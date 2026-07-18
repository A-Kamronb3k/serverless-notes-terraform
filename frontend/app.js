(function () {
  "use strict";

  const config = window.APP_CONFIG || {};
  const apiUrl = (config.apiUrl || "").replace(/\/$/, "");

  const els = {
    error: document.getElementById("error-banner"),
    loading: document.getElementById("loading"),
    empty: document.getElementById("empty"),
    list: document.getElementById("notes-list"),
    createForm: document.getElementById("create-form"),
    createTitle: document.getElementById("create-title"),
    createContent: document.getElementById("create-content"),
    createSubmit: document.getElementById("create-submit"),
  };

  let notes = [];

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

    let res;
    try {
      res = await fetch(`${apiUrl}${path}`, {
        headers: { "Content-Type": "application/json", ...(options.headers || {}) },
        ...options,
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

  loadNotes();
})();
