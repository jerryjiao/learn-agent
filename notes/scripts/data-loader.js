// Data Loader
async function loadNotes() {
    try {
        // Try to load notes.json first
        const response = await fetch('notes.json');
        if (!response.ok) {
            throw new Error('Failed to load notes.json');
        }

        const data = await response.json();

        // Update stats
        document.getElementById('note-count').textContent = data.total;

        // Initialize search with notes
        const notes = data.notes || [];
        new NoteSearch(notes);

    } catch (error) {
        console.error('Failed to load notes:', error);

        // Fallback: scan for markdown files
        const notes = await scanForNotes();

        // Update stats
        document.getElementById('note-count').textContent = notes.length;

        // Initialize search
        new NoteSearch(notes);
    }
}

// Fallback: Scan for markdown files
async function scanForNotes() {
    const notes = [];

    try {
        // Get all markdown files
        const response = await fetch('/');
        const html = await response.text();

        // Parse HTML to find .md files (this is a simple approach)
        // In production, you'd have a proper index file
        const parser = new DOMParser();
        const doc = parser.parseFromString(html, 'text/html');
        const links = doc.querySelectorAll('a[href$=".md"]');

        links.forEach(link => {
            const href = link.getAttribute('href');
            const filename = href.replace(/\.md$/, '');

            // Skip README
            if (filename === 'README') return;

            notes.push({
                id: filename,
                title: link.textContent || filename,
                path: href,
                excerpt: '点击查看笔记内容...'
            });
        });

    } catch (error) {
        console.error('Failed to scan for notes:', error);
    }

    return notes;
}

// Sidebar toggle for mobile
document.addEventListener('DOMContentLoaded', () => {
    const toggleBtn = document.getElementById('toggle-sidebar');
    const sidebar = document.getElementById('sidebar');

    if (toggleBtn && sidebar) {
        toggleBtn.addEventListener('click', () => {
            sidebar.classList.toggle('open');
        });

        // Close sidebar when clicking outside on mobile
        document.addEventListener('click', (e) => {
            if (window.innerWidth <= 768) {
                if (!sidebar.contains(e.target) && !toggleBtn.contains(e.target)) {
                    sidebar.classList.remove('open');
                }
            }
        });
    }
});
