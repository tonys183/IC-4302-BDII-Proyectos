function showItemSelect() {
    const itemType = document.getElementById('itemType').value;
    
    // Ocultar todos los grupos
    document.getElementById('bookGroup').style.display = 'none';
    document.getElementById('supplyGroup').style.display = 'none';
    document.getElementById('serviceGroup').style.display = 'none';
    
    // Limpiar los selects
    document.getElementById('bookId').value = '';
    document.getElementById('supplyId').value = '';
    document.getElementById('serviceId').value = '';
    
    // Mostrar el grupo correspondiente
    if (itemType === 'book') {
        document.getElementById('bookGroup').style.display = 'block';
    } else if (itemType === 'supply') {
        document.getElementById('supplyGroup').style.display = 'block';
    } else if (itemType === 'service') {
        document.getElementById('serviceGroup').style.display = 'block';
    }
}
