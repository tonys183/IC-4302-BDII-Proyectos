function showItemSelect() {
    const itemType = document.getElementById('itemType').value;

    document.getElementById('bookGroup').style.display = 'none';
    document.getElementById('supplyGroup').style.display = 'none';
    document.getElementById('serviceGroup').style.display = 'none';

    document.getElementById('bookId').value = '';
    document.getElementById('supplyId').value = '';
    document.getElementById('serviceId').value = '';

    document.getElementById('bookId').required = false;
    document.getElementById('supplyId').required = false;
    document.getElementById('serviceId').required = false;

    if (itemType === 'book') {
        document.getElementById('bookGroup').style.display = 'block';
        document.getElementById('bookId').required = true;
    } else if (itemType === 'supply') {
        document.getElementById('supplyGroup').style.display = 'block';
        document.getElementById('supplyId').required = true;
    } else if (itemType === 'service') {
        document.getElementById('serviceGroup').style.display = 'block';
        document.getElementById('serviceId').required = true;
    }
}
