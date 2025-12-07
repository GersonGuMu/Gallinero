<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Manejo de preflight (CORS)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// ---- CONFIGURACIÓN BD ----
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "sensoresdb";

// Crear conexión
$conn = new mysqli($servername, $username, $password, $dbname);

// Revisar conexión
if ($conn->connect_error) {
    die(json_encode(["error" => "Conexión fallida: " . $conn->connect_error]));
}

// ==================================================================================
// POST: Guardar datos y Limpiar antiguos (Autolimpieza 5s)
// ==================================================================================
if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    // Nota: Usamos $_POST porque Python requests.post(data=...) envía datos de formulario.
    // Usamos 'isset' para evitar errores si el Arduino no envía algún campo todavía.
    
    $temperatura       = isset($_POST['temperatura']) ? $_POST['temperatura'] : 0;
    $humedad           = isset($_POST['humedad']) ? $_POST['humedad'] : 0;
    $nivel_agua        = isset($_POST['nivel_agua']) ? $_POST['nivel_agua'] : 0;
    $bomba_estado      = isset($_POST['bomba_estado']) ? $_POST['bomba_estado'] : 0;
    $ventilador_estado = isset($_POST['ventilador_estado']) ? $_POST['ventilador_estado'] : 0;
    
    // NUEVOS CAMPOS
    $nivel_comida      = isset($_POST['nivel_comida']) ? $_POST['nivel_comida'] : 0;
    $luces_estado      = isset($_POST['luces_estado']) ? $_POST['luces_estado'] : 0;

    // Insertar en la base de datos
    $sqlInsert = "INSERT INTO datos_sensor 
                  (temperatura, humedad, nivel_agua, bomba_estado, ventilador_estado, nivel_comida, luces_estado, fecha)
                  VALUES 
                  ('$temperatura', '$humedad', '$nivel_agua', '$bomba_estado', '$ventilador_estado', '$nivel_comida', '$luces_estado', NOW())";

    if ($conn->query($sqlInsert) === TRUE) {
        
        // 3. MAGIA: Eliminar registros antiguos (> 5 segundos)
        $sqlClean = "DELETE FROM datos_sensor WHERE fecha < (NOW() - INTERVAL 10 SECOND)";
        $conn->query($sqlClean);

        // Respuesta JSON limpia (Sin echo de texto plano antes)
        echo json_encode([
            "success" => true, 
            "message" => "Datos guardados y limpieza de 5s ejecutada correctamente"
        ]);

    } else {
        echo json_encode(["error" => "Error SQL: " . $conn->error]);
    }
    
    exit();
}

// ==================================================================================
// GET: Obtener el dato más reciente (Para tu web/app)
// ==================================================================================
if ($_SERVER['REQUEST_METHOD'] === 'GET') {

    $sql = "SELECT * FROM datos_sensor ORDER BY fecha ASC LIMIT 1";
    $res = $conn->query($sql);

    if ($res && $res->num_rows > 0) {
        $row = $res->fetch_assoc();
        echo json_encode($row);
    } else {
        echo json_encode(["status" => "vacio", "mensaje" => "No hay datos recientes"]);
    }
    
    exit();
}

$conn->close();
?>