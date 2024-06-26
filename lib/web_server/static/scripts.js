document.addEventListener('DOMContentLoaded', () => {
    const PAGE_SIZE = 10;
    let currentPage = 1;
    let searchPerformed = false;

    const requestsList = document.getElementById('requests-list');
    const requestTemplate = document.getElementById('request-template');
    const paginationInfo = document.getElementById('pagination-info');
    const prevPageButton = document.getElementById('prev-page');
    const nextPageButton = document.getElementById('next-page');
    const noResultsText = document.getElementById('no-results-text');
    const searchInput = document.getElementById('search-input');

    const popupBox = document.getElementById('popup-box');
    const popupName = document.getElementById('popup-name');
    const popupEmail = document.getElementById('popup-email');
    const popupDescription = document.getElementById('popup-description');
    const popupImage = document.getElementById('popup-image');
    const closeBtn = document.querySelector('.close-btn');

    async function fetchRequests(page, pageSize, searchQuery = '') {
        let url = `/requests?page=${page}&pageSize=${pageSize}`;
        if (searchQuery) {
            url += `&search=${encodeURIComponent(searchQuery)}`;
        }

        try {
            const response = await fetch(url);
            return await response.json();
        } catch (error) {
            console.error('Error fetching requests:', error);
            return { requests: [], totalItems: 0 };
        }
    }

    function renderRequestList(requests) {
        requestsList.innerHTML = '';
    
        requests.forEach((request, index) => {
            const clone = requestTemplate.content.cloneNode(true);
            const srNoElement = clone.querySelector('.sr-no');
            const nameElement = clone.querySelector('.name');
            const approveButton = clone.querySelector('.approve-btn');
            const rejectButton = clone.querySelector('.reject-btn'); 
    
            srNoElement.textContent = (currentPage - 1) * PAGE_SIZE + index + 1;
            nameElement.textContent = request.name;
    
            nameElement.addEventListener('click', (event) => {
                event.preventDefault();
                showPopup(request);
            });

            approveButton.addEventListener('click', async () => { 
                await approveRequest(request.user_id);
            });
    
            rejectButton.addEventListener('click', async () => { 
                await rejectRequest(request.user_id);
            });
    
            requestsList.appendChild(clone);
        });
    }

    function renderPaginationInfo(startIndex, endIndex, totalItems) {
        paginationInfo.textContent = `${startIndex}-${endIndex} of ${totalItems}`;
        prevPageButton.disabled = currentPage === 1;
        nextPageButton.disabled = endIndex === totalItems;
    }

    function renderNoResultsText(show) {
        noResultsText.style.display = show ? 'block' : 'none';
    }

    async function renderRequests(page, pageSize, searchQuery = '') {
        const responseData = await fetchRequests(page, pageSize, searchQuery);
        const requestData = responseData.requests;
    
        const totalItems = responseData.totalItems;
        const resultsFound = requestData.length > 0;
    
        const startIndex = (page - 1) * pageSize + 1;
        const endIndex = Math.min(startIndex + pageSize - 1, totalItems);
    
        renderRequestList(requestData);
        renderPaginationInfo(resultsFound ? startIndex : 0, endIndex, totalItems);

        if (searchPerformed && totalItems > pageSize) {
            prevPageButton.disabled = page === 1;
            nextPageButton.disabled = endIndex === totalItems;
        } else {
            prevPageButton.disabled = true;
            nextPageButton.disabled = true;
        }

        if (!searchPerformed) {
            prevPageButton.disabled = page === 1 || !totalItems || totalItems <= PAGE_SIZE;
            nextPageButton.disabled = endIndex === totalItems || !totalItems || totalItems <= PAGE_SIZE;
        }
    
        renderNoResultsText(!resultsFound);
    }    

    // Function to handle rejection of a request
    async function rejectRequest(userId) {
        console.log('Rejecting request for user:', userId);
        try {
            const response = await fetch('/reject-request', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ userId: userId })
            });
    
            if (response.ok) {
                console.log('Request rejected successfully');
                renderRequests(currentPage, PAGE_SIZE, '');
                searchPerformed = false;
                searchInput.value = '';
            } else {
                console.error('Failed to reject request');
            }
        } catch (error) {
            console.error('Error rejecting request:', error);
        }
    }

    // Function to handle approval of a request
    async function approveRequest(userId) {
        console.log('Accepting request for user:', userId);
        try {
            const response = await fetch('/accept-request', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ userId: userId })
            });
    
            if (response.ok) {
                console.log('Request approved successfully');
                renderRequests(currentPage, PAGE_SIZE, '');
                searchPerformed = false;
                searchInput.value = '';
            } else {
                console.error('Failed to accept request');
            }
        } catch (error) {
            console.error('Error accepting request:', error);
        }
    }
    
    function showPopup(request) {
        popupName.textContent = request.name;
        popupEmail.textContent = request.email;
        popupDescription.textContent = request.description;
        popupImage.src = request.uploaded_url;

        popupBox.style.display = 'block';
    }

    function handleSearch() {
        const searchQuery = searchInput.value.trim();
        searchPerformed = true;
        renderRequests(1, PAGE_SIZE, searchQuery);
    }

    searchInput.addEventListener('input', handleSearch);

    prevPageButton.addEventListener('click', () => {
        if (currentPage > 1) {
            currentPage--;
            renderRequests(currentPage, PAGE_SIZE, searchInput.value.trim());
        }
    });

    nextPageButton.addEventListener('click', () => {
        currentPage++;
        renderRequests(currentPage, PAGE_SIZE, searchInput.value.trim());
    });

    closeBtn.addEventListener('click', () => {
        popupBox.style.display = 'none';
    });

    window.addEventListener('click', (event) => {
        if (event.target === popupBox) {
            popupBox.style.display = 'none';
        }
    });

    renderRequests(currentPage, PAGE_SIZE);
});
