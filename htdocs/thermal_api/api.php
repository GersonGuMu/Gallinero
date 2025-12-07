<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Manejo de preflight (CORS)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// ---- CONFIG BD ----
$host = "localhost";
$user = "root";
$pass = "";
$dbname = "sensoresdb";

// Conexión
$conn = new mysqli($host, $user, $pass, $dbname);

if ($conn->connect_error) {
    die(json_encode(["error" => "Error de conexión: " . $conn->connect_error]));
}

// Solo manejaremos un registro (ID = 1)
$sqlFindId = "SELECT id FROM datos_sensor ORDER BY id ASC LIMIT 1";
$resultId = $conn->query($sqlFindId);

if ($resultId && $resultId->num_rows > 0) {
    $rowId = $resultId->fetch_assoc();
    $recordId = $rowId['id']; // Aquí guardamos el ID real (ej. 1, 45, etc.)
} else {
    // Si la tabla está vacía, detenemos todo
    die(json_encode(["error" => "La tabla 'datos_sensor' está vacía. Inserta al menos un registro."]));
}

// ----------------------------------------------------------------------------------
// GET → Obtener datos de la tabla
// ----------------------------------------------------------------------------------
if ($_SERVER['REQUEST_METHOD'] === 'GET') {

    $sql = "SELECT ventilador_estado, temperatura, humedad, fecha
            FROM datos_sensor 
            WHERE id = $recordId LIMIT 1";

    $res = $conn->query($sql);

    if ($res && $res->num_rows > 0) {

        $row = $res->fetch_assoc();

        echo json_encode([
            "ventilador_estado"   => boolval($row["ventilador_estado"]),
            "temperatura" => floatval($row["temperatura"]),
            "humedad"     => floatval($row["humedad"]),
            "fecha"=> $row["fecha"]
        ]);

    } else {
        echo json_encode(["error" => "No hay datos"]);
    }

    exit();
}

// ----------------------------------------------------------------------------------
// POST → Actualizar datos
// ----------------------------------------------------------------------------------
if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    $body = file_get_contents("php://input");
    $data = json_decode($body, true);

    if (!$data) {
        echo json_encode(["error" => "JSON inválido"]);
        exit();
    }

    $ventilador = isset($data["ventilador_estado"]) ? intval($data["ventilador_estado"]) : 0;
    //$temp       = isset($data["temperatura"]) ? floatval($data["temperatura"]) : 22;
    //$humedad    = isset($data["humedad"]) ? floatval($data["humedad"]) : 50;

    $sql = "UPDATE datos_sensor SET 
                ventilador_estado = $ventilador,
                
                fecha = NOW()
            WHERE id = $recordId";

    if ($conn->query($sql) === TRUE) {
        echo json_encode([
            "success" => true,
            "message" => "Datos actualizados correctamente",
        ]);
    } else {
        echo json_encode(["error" => "Error al guardar: " . $conn->error]);
    }

    exit();
}

// ----------------------------------------------------------------------------------
echo json_encode(["error" => "Método no permitido"]);
$conn->close();
?>
