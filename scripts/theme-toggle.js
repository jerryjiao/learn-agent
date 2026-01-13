// Theme Toggle
class ThemeToggle {
    constructor() {
        this.toggleBtn = document.getElementById('theme-toggle');
        this.sunIcon = this.toggleBtn.querySelector('.sun-icon');
        this.moonIcon = this.toggleBtn.querySelector('.moon-icon');
        this.currentTheme = this.getStoredTheme() || this.getPreferredTheme();

        this.init();
    }

    getPreferredTheme() {
        return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    }

    getStoredTheme() {
        return localStorage.getItem('theme');
    }

    setTheme(theme) {
        document.documentElement.setAttribute('data-theme', theme);
        localStorage.setItem('theme', theme);
        this.currentTheme = theme;
        this.updateIcons();
    }

    updateIcons() {
        if (this.currentTheme === 'dark') {
            this.sunIcon.style.display = 'none';
            this.moonIcon.style.display = 'block';
        } else {
            this.sunIcon.style.display = 'block';
            this.moonIcon.style.display = 'none';
        }
    }

    toggle() {
        const newTheme = this.currentTheme === 'dark' ? 'light' : 'dark';
        this.setTheme(newTheme);
    }

    init() {
        // Set initial theme
        this.setTheme(this.currentTheme);

        // Add click handler
        this.toggleBtn.addEventListener('click', () => this.toggle());

        // Listen for system theme changes
        window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
            if (!this.getStoredTheme()) {
                this.setTheme(e.matches ? 'dark' : 'light');
            }
        });
    }
}

// Initialize on DOM load
document.addEventListener('DOMContentLoaded', () => {
    new ThemeToggle();
});
