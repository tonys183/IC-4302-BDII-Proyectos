let searchTimeout;

function debounceSearch() {
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(() => {
        performSearch();
    }, 300);
}

function performSearch() {
    const type = document.getElementById('type').value;
    const search = document.getElementById('search')?.value || '';
    const genre = document.getElementById('genre')?.value || '';
    const author = document.getElementById('author')?.value || '';

    if (type === 'books') {
        fetch(`/catalog/search?type=${type}&search=${encodeURIComponent(search)}&genre=${encodeURIComponent(genre)}&author=${encodeURIComponent(author)}`)
            .then(response => response.text())
            .then(html => {
                const parser = new DOMParser();
                const doc = parser.parseFromString(html, 'text/html');
                const booksResults = doc.getElementById('books-results');
                
                if (booksResults) {
                    document.getElementById('books-results').innerHTML = booksResults.innerHTML;
                }
            })
            .catch(error => {
            });
    }
}

function submitForm() {
    document.getElementById('searchForm').submit();
}

window.addEventListener('beforeunload', function() {
    clearTimeout(searchTimeout);
});
