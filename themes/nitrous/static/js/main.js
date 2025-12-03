// nitrousOS Website JavaScript

// Mobile navigation toggle
document.addEventListener('DOMContentLoaded', function() {
  const navToggle = document.querySelector('.nav-toggle');
  const navMenu = document.querySelector('.nav-menu');

  if (navToggle && navMenu) {
    navToggle.addEventListener('click', function() {
      navMenu.classList.toggle('active');
      navToggle.classList.toggle('active');
    });

    // Close menu when clicking outside
    document.addEventListener('click', function(e) {
      if (!navToggle.contains(e.target) && !navMenu.contains(e.target)) {
        navMenu.classList.remove('active');
        navToggle.classList.remove('active');
      }
    });

    // Close menu when clicking a link
    navMenu.querySelectorAll('a').forEach(function(link) {
      link.addEventListener('click', function() {
        navMenu.classList.remove('active');
        navToggle.classList.remove('active');
      });
    });
  }

  // Smooth scroll for anchor links
  document.querySelectorAll('a[href^="#"]').forEach(function(anchor) {
    anchor.addEventListener('click', function(e) {
      const targetId = this.getAttribute('href');
      if (targetId !== '#') {
        const target = document.querySelector(targetId);
        if (target) {
          e.preventDefault();
          target.scrollIntoView({ behavior: 'smooth' });
        }
      }
    });
  });

  // Add copy button to code blocks
  document.querySelectorAll('pre code').forEach(function(codeBlock) {
    const pre = codeBlock.parentElement;
    const button = document.createElement('button');
    button.className = 'copy-btn';
    button.textContent = 'Copy';
    button.setAttribute('aria-label', 'Copy code to clipboard');

    button.addEventListener('click', function() {
      navigator.clipboard.writeText(codeBlock.textContent).then(function() {
        button.textContent = 'Copied!';
        setTimeout(function() {
          button.textContent = 'Copy';
        }, 2000);
      });
    });

    pre.style.position = 'relative';
    pre.appendChild(button);
  });
});

// Add styles for copy button
const style = document.createElement('style');
style.textContent = `
  .copy-btn {
    position: absolute;
    top: 0.5rem;
    right: 0.5rem;
    padding: 0.25rem 0.5rem;
    font-size: 0.75rem;
    font-family: inherit;
    background: var(--color-bg-tertiary, #21262d);
    color: var(--color-text-muted, #8b949e);
    border: 1px solid var(--color-border, #30363d);
    border-radius: 4px;
    cursor: pointer;
    opacity: 0;
    transition: opacity 0.2s;
  }
  pre:hover .copy-btn {
    opacity: 1;
  }
  .copy-btn:hover {
    background: var(--color-border, #30363d);
    color: var(--color-text, #e6edf3);
  }
`;
document.head.appendChild(style);
