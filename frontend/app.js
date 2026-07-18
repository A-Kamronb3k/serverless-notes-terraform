(function () {
  "use strict";

  const AUTH_TOKEN_KEY = "auth_token";
  const config = window.APP_CONFIG || {};
  const apiUrl = (config.apiUrl || "").replace(/\/$/, "");
  const cognitoDomain = (config.cognitoDomain || "").replace(/\/$/, "");
  const cognitoClientId = config.cognitoClientId || "";

  const els = {
    error: document.getElementById("error-banner"),
    loading: document.getElementById("loading"),
    empty: document.getElementById("empty"),
    list: document.getElementById("notes-list"),
    createForm: document.getElementById("create-form"),
    createTitle: document.getElementById("create-title"),
    createContent: document.getElementById("create-content"),
    createSubmit: document.getElementById("create-submit"),
    authButton: document.getElementById("auth-button"),
  };

  let notes = [];

  function getAuthToken() {
    return localStorage.getItem(AUTH_TOKEN_KEY);
  }

  function setAuthToken(token) {
    localStorage.setItem(AUTH_TOKEN_KEY, token);
  }

  function clearAuthToken() {
    localStorage.removeItem(AUTH_TOKEN_KEY);
  }

  function isLoggedIn() {
    return Boolean(getAuthToken());
  }

  function regionFromApiUrl() {
    const match = apiUrl.match(/execute-api\.([a-z0-9-]+)\.amazonaws\.com/i);
    return (match && match[1]) || "eu-north-1";
  }

  function hostedUiBaseUrl() {
    if (!cognitoDomain) {
      return "";
    }
    if (/^https?:\/\//i.test(cognitoDomain) || cognitoDomain.includes("amazoncognito.com")) {
      return cognitoDomain.replace(/^https?:\/\//i, "https://");
    }
    return `https://${cognitoDomain}.auth.${regionFromApiUrl()}.amazoncognito.com`;
  }

  function captureTokenFromHash() {
    const hash = window.location.hash.startsWith("#")
      ? window.location.hash.slice(1)
      : window.location.hash;
    if (!hash) {
      return;
    }

    const params = new URLSearchParams(hash);
    const token = params.get("id_token") || params.get("access_token");
    if (!token) {
      return;
    }

    setAuthToken(token);
    history.replaceState(null, "", window.location.pathname + window.location.search);
  }

  function loginUrl() {
    const base = hostedUiBaseUrl();
    if (!base || !cognitoClientId) {
      throw new Error("Cognito is not configured. Set cognitoDomain and cognitoClientId in config.js.");
    }

    const params = new URLSearchParams({
      client_id: cognitoClientId,
      response_type: "token",
      scope: "email openid",
      redirect_uri: window.location.origin,
    });
    return `${base}/login?${params.toString()}`;
  }

  function updateAuthButton() {
    if (isLoggedIn()) {
      els.authButton.textContent = "Logout";
      els.authButton.classList.add("is-logout");
    } else {
      els.authButton.textContent = "Login";
      els.authButton.classList.remove("is-logout");
    }
  }

  els.authButton.addEventListener("click", () => {
    clearError();
    if (isLoggedIn()) {
      clearAuthToken();
      window.location.reload();
      return;
    }
    try {
      window.location.assign(loginUrl());
    } catch (err) {
      showError(err.message);
    }
  });

  function showError(message) {
    els.error.hidden = false;
    els.error.textContent = message;
  }

  function clearError() {
    els.error.hidden = true;
    els.error.textContent = "";
  }

  function setLoading(isLoading) {
    els.loading.hidden = !isLoading;
    if (isLoading) {
      els.empty.hidden = true;
    }
  }

  function formatUpdatedAt(iso) {
    if (!iso) return "";
    const date = new Date(iso);
    if (Number.isNaN(date.getTime())) return iso;
    return date.toLocaleString(undefined, {
      dateStyle: "medium",
      timeStyle: "short",
    });
  }

  async function api(path, options = {}) {
    if (!apiUrl) {
      throw new Error("API URL is not configured. Copy config.example.js to config.js.");
    }

    const method = (options.method || "GET").toUpperCase();
    const headers = {
      "Content-Type": "application/json",
      ...(options.headers || {}),
    };

    if (method === "POST" || method === "PUT" || method === "DELETE") {
      const token = getAuthToken();
      if (token) {
        headers.Authorization = `Bearer ${token}`;
      }
    }

    let res;
    try {
      res = await fetch(`${apiUrl}${path}`, {
        ...options,
        method,
        headers,
      });
    } catch {
      throw new Error("Network error — could not reach the API.");
    }

    if (res.status === 204) {
      return null;
    }

    let body = null;
    const text = await res.text();
    if (text) {
      try {
        body = JSON.parse(text);
      } catch {
        body = null;
      }
    }

    if (!res.ok) {
      const msg =
        (body && body.error) ||
        (body && body.message) ||
        (res.status === 401 && "Unauthorized — please log in") ||
        (res.status === 403 && "Forbidden") ||
        (res.status === 400 && "Bad request") ||
        (res.status === 404 && "Not found") ||
        (res.status === 500 && "Internal server error") ||
        `Request failed (${res.status})`;
      throw new Error(msg);
    }

    return body;
  }

  function renderList() {
    while (els.list.firstChild) {
      els.list.removeChild(els.list.firstChild);
    }

    els.empty.hidden = notes.length > 0;

    for (const note of notes) {
      els.list.appendChild(createNoteCard(note));
    }
  }

  function createNoteCard(note) {
    const li = document.createElement("li");
    li.className = "note-card";
    li.dataset.id = note.id;

    const titleEl = document.createElement("h3");
    titleEl.className = "note-title";
    titleEl.textContent = note.title || "";

    const contentEl = document.createElement("p");
    contentEl.className = "note-content";
    contentEl.textContent = note.content || "";

    const metaEl = document.createElement("p");
    metaEl.className = "note-meta";
    metaEl.textContent = note.updated_at
      ? `Updated ${formatUpdatedAt(note.updated_at)}`
      : "";

    const actions = document.createElement("div");
    actions.className = "card-actions";

    const editBtn = document.createElement("button");
    editBtn.type = "button";
    editBtn.className = "btn-edit";
    editBtn.textContent = "Edit";
    editBtn.addEventListener("click", () => enterEditMode(li, note));

    const deleteBtn = document.createElement("button");
    deleteBtn.type = "button";
    deleteBtn.className = "btn-delete";
    deleteBtn.textContent = "Delete";
    deleteBtn.addEventListener("click", () => onDelete(note.id));

    actions.append(editBtn, deleteBtn);
    li.append(titleEl, contentEl, metaEl, actions);
    return li;
  }

  function enterEditMode(li, note) {
    li.classList.add("is-editing");
    while (li.firstChild) {
      li.removeChild(li.firstChild);
    }

    const form = document.createElement("form");
    form.className = "note-form";

    const titleLabel = document.createElement("label");
    titleLabel.textContent = "Title";
    const titleInput = document.createElement("input");
    titleInput.type = "text";
    titleInput.name = "title";
    titleInput.maxLength = 200;
    titleInput.required = true;
    titleInput.value = note.title || "";
    titleLabel.appendChild(titleInput);

    const contentLabel = document.createElement("label");
    contentLabel.textContent = "Content";
    const contentInput = document.createElement("textarea");
    contentInput.name = "content";
    contentInput.maxLength = 5000;
    contentInput.rows = 4;
    contentInput.value = note.content || "";
    contentLabel.appendChild(contentInput);

    const actions = document.createElement("div");
    actions.className = "card-actions";

    const saveBtn = document.createElement("button");
    saveBtn.type = "submit";
    saveBtn.className = "btn-save";
    saveBtn.textContent = "Save";

    const cancelBtn = document.createElement("button");
    cancelBtn.type = "button";
    cancelBtn.className = "btn-cancel";
    cancelBtn.textContent = "Cancel";
    cancelBtn.addEventListener("click", () => {
      renderList();
    });

    actions.append(saveBtn, cancelBtn);
    form.append(titleLabel, contentLabel, actions);

    form.addEventListener("submit", async (event) => {
      event.preventDefault();
      clearError();
      saveBtn.disabled = true;
      cancelBtn.disabled = true;
      try {
        const updated = await api(`/notes/${encodeURIComponent(note.id)}`, {
          method: "PUT",
          body: JSON.stringify({
            title: titleInput.value.trim(),
            content: contentInput.value,
          }),
        });
        const index = notes.findIndex((n) => n.id === note.id);
        if (index !== -1) {
          notes[index] = updated;
        }
        renderList();
      } catch (err) {
        showError(err.message);
        saveBtn.disabled = false;
        cancelBtn.disabled = false;
      }
    });

    li.appendChild(form);
    titleInput.focus();
  }

  async function onDelete(id) {
    if (!window.confirm("Delete this note? This cannot be undone.")) {
      return;
    }
    clearError();
    try {
      await api(`/notes/${encodeURIComponent(id)}`, { method: "DELETE" });
      notes = notes.filter((n) => n.id !== id);
      renderList();
    } catch (err) {
      showError(err.message);
    }
  }

  async function loadNotes() {
    clearError();
    setLoading(true);
    try {
      const data = await api("/notes");
      notes = (data && data.items) || [];
      renderList();
    } catch (err) {
      notes = [];
      renderList();
      showError(err.message);
    } finally {
      setLoading(false);
    }
  }

  els.createForm.addEventListener("submit", async (event) => {
    event.preventDefault();
    clearError();
    els.createSubmit.disabled = true;
    try {
      const created = await api("/notes", {
        method: "POST",
        body: JSON.stringify({
          title: els.createTitle.value.trim(),
          content: els.createContent.value,
        }),
      });
      notes.unshift(created);
      els.createForm.reset();
      renderList();
    } catch (err) {
      showError(err.message);
    } finally {
      els.createSubmit.disabled = false;
    }
  });

  captureTokenFromHash();
  updateAuthButton();
  loadNotes();
})();
