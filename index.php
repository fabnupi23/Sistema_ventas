<?php
//primero vamos a verificar cuando el usuario haya dado click en ingresar
$alert = '';

if (!empty($_SESSION['active'])) {
    header('location: principal.php');
} else {




    if (!empty($_POST)) { //empty quiere decir "si no existe" o "esta vacio" en este caso es negación

        //Ahora vamos a verificar que usuario y contraseña no esten vacios.
        if (empty($_POST['usuario']) || empty($_POST['clave'])) {
            echo $alert = 'Ingrese usuario y contraseña';
        } else {
            require_once "conexion.php"; //por medio de este archivo hacemos la conexion a la Base de Datos

            /*Aca se almacenan los datos ingresados */
            $user = $_POST['usuario'];
            $pass = $_POST['clase'];
            //-------------------------------------------

            $query = mysqli_query($conection, "SELECT * FROM usuario WHERE usuario= '$user' 
        AND clave = '$pass' "); //esta funcion requiere de dos parametros, la pprimera variable que tiene la conexion.
            $result = mysqli_num_rows($query); //aca nos devuelve un numero.

            if ($result > 0) { //quiere decir que si encuentra un registro en donde coincida la condicion del query, lo va a guardar en result.
                //vamos a crear un array que nos devuelve el query
                $data = mysqli_fetch_array($query); //aca nos guarda lo que nos devuelve la consulta.
                session_start(); //Con esto estamos indicando  que estamos iniciando una sesion.

                //Creamos las variables de sesion
                $_SESSION['active'] = true;
                $_SESSION['idUser'] = $data['idusuario'];
                $_SESSION['nombre'] = $data['nombre'];
                $_SESSION['email'] = $data['email'];
                $_SESSION['user'] = $data['usuario'];
                $_SESSION['rol'] = $data['rol'];

                header('location: principal.php');
            } else {
                $alert = 'El usuario o contraseña no son correctos';
                session_destroy(); //aca destruimos la sesion.
            }
        }
    }
}
?>

<!DOCTYPE html>
<html lang="es">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login | Software Engineer</title>
    <link rel="stylesheet" type="text/css" href="css/style.css">
</head>

<body>
    <div class="cod-container">
        <div class="form-header">
            <img src="img/Logo.png" alt="Logo">
            <h1>Softnup <span>Solutions</span></h1>
        </div>
        <div class="form-content">
            <form action="#" class="cod-form">
                <div class="form-title">
                    <h3>Iniciar Sesión</h3>
                </div>

                <div class="input-group">
                    <input type="text" class="form-input" name="form-input">
                    <label class="label" for="usuario" name="usuario">Usuario</label>
                </div>
                <div class="input-group">
                    <input type="password" class="form-input" name="form-input" id="pass">
                    <label class="label" for="pass" name="clave">Contraseña</label>
                    <div class="alert"><?php echo isset($alert) ? $alert : ''; ?></div>
                </div>

                <div class="input-group">
                    <input type="submit" class="form-input" value="Iniciar Sesión">
                    <p>No tienes cuenta? <a href="#">Ingresa aqui¡¡</a></p>
                </div>
            </form>
        </div>
    </div>
</body>

</html>