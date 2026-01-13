// Note Search
class NoteSearch {
    constructor(notes) {
        this.notes = notes;
        this.searchInput = document.getElementById('search-input');
        this.clearBtn = document.getElementById('clear-search');
        this.notesNav = document.getElementById('notes-nav');

        this.init();
    }

    search(query) {
        const searchTerm = query.toLowerCase().trim();

        if (!searchTerm) {
            this.renderNotes(this.notes);
            this.clearBtn.style.display = 'none';
            return;
        }

        this.clearBtn.style.display = 'block';

        const filtered = this.notes.filter(note => {
            const title = note.title.toLowerCase();
            const content = note.content ? note.content.toLowerCase() : '';
            const excerpt = note.excerpt ? note.excerpt.toLowerCase() : '';

            return title.includes(searchTerm) ||
                   content.includes(searchTerm) ||
                   excerpt.includes(searchTerm);
        });

        this.renderNotes(filtered);
    }

    clearSearch() {
        this.searchInput.value = '';
        this.renderNotes(this.notes);
        this.clearBtn.style.display = 'none';
    }

    renderNotes(notes) {
        if (notes.length === 0) {
            this.notesNav.innerHTML = '<div class="loading">没有找到匹配的笔记</div>';
            return;
        }

        this.notesNav.innerHTML = notes.map(note => `
            <a class="note-item" data-note="${note.id}">
                <div class="note-item-title">${this.escapeHtml(note.title)}</div>
                <div class="note-item-excerpt">${this.escapeHtml(note.excerpt)}</div>
            </a>
        `).join('');

        // Add click handlers
        document.querySelectorAll('.note-item').forEach(item => {
            item.addEventListener('click', (e) => {
                e.preventDefault();
                const noteId = item.getAttribute('data-note');
                this.loadNote(noteId);
            });
        });
    }

    loadNote(noteId) {
        const note = this.notes.find(n => n.id === noteId);
        if (!note) return;

        // Update active state
        document.querySelectorAll('.note-item').forEach(item => {
            item.classList.remove('active');
            if (item.getAttribute('data-note') === noteId) {
                item.classList.add('active');
            }
        });

        // Load note content
        const noteContent = document.getElementById('note-content');
        const currentTitle = document.getElementById('current-title');

        if (note.content) {
            currentTitle.textContent = note.title;
            noteContent.innerHTML = this.markdownToHtml(note.content);
        } else {
            // Fetch note file
            fetch(`${note.id}.md`)
                .then(response => response.text())
                .then(markdown => {
                    currentTitle.textContent = note.title;
                    noteContent.innerHTML = this.markdownToHtml(markdown);
                    // Cache content
                    note.content = markdown;
                })
                .catch(err => {
                    console.error('Failed to load note:', err);
                    noteContent.innerHTML = '<div class="loading">加载失败</div>';
                });
        }
    }

    // Simple markdown parser
    markdownToHtml(markdown) {
        let html = markdown;

        // Code blocks
        html = html.replace(/```(\w+)?\n([\s\S]*?)```/g, '<pre><code>$2</code></pre>');

        // Inline code
        html = html.replace(/`([^`]+)`/g, '<code>$1</code>');

        // Headers
        html = html.replace(/^### (.+)$/gm, '<h3>$1</h3>');
        html = html.replace(/^## (.+)$/gm, '<h2>$1</h2>');
        html = html.replace(/^# (.+)$/gm, '<h1>$1</h1>');

        // Bold
        html = html.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');

        // Italic
        html = html.replace(/\*(.+?)\*/g, '<em>$1</em>');

        // Links
        html = html.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" target="_blank">$1</a>');

        // Unordered lists
        html = html.replace(/^\- (.+)$/gm, '<li>$1</li>');
        html = html.replace(/(<li>.*<\/li>)/s, '<ul>$1</ul>');

        // Ordered lists
        html = html.replace(/^\d+\. (.+)$/gm, '<li>$1</li>');

        // Paragraphs
        html = html.replace(/\n\n/g, '</p><p>');
        html = '<p>' + html + '</p>';

        // Clean up empty paragraphs
        html = html.replace(/<p><\/p>/g, '');
        html = html.replace(/<p>(<h[1-3]>)/g, '$1');
        html = html.replace(/(<\/h[1-3]>)<\/p>/g, '$1');
        html = html.replace(/<p>(<ul>)/g, '$1');
        html = html.replace(/(<\/ul>)<\/p>/g, '$1');
        html = html.replace(/<p>(<pre>)/g, '$1');
        html = html.replace(/(<\/pre>)<\/p>/g, '$1');

        // Blockquotes
        html = html.replace(/^> (.+)$/gm, '<blockquote>$1</blockquote>');

        return html;
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    init() {
        // Search input handler
        this.searchInput.addEventListener('input', (e) => {
            this.search(e.target.value);
        });

        // Clear button handler
        this.clearBtn.addEventListener('click', () => {
            this.clearSearch();
        });

        // Initial render
        this.renderNotes(this.notes);
    }
}
