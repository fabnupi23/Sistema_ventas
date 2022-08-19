<?php 
/*------Creamos variables de conexion---------------------------- */
    $host = 'localhost';
    $user = 'root';
    $password = '';
    $db = 'fiesta';
/*-----------------------------------------------------------------*/

/*------realizamos la conexion------------------------------------ */
    $conection = @mysqli_connect($host,$user,$password,$db);//Por medio de la funcion mysqli_connect nos conecamos a la Base de Datos
/*-----------------------------------------------------------------*/

    if (!$conection) {// si no se da la conexion me imprime un mensaje
        echo"Error en la conexión, por favor contacta al administrador del sistema.";
    }/*else{
        echo"Conexión Exitosa.";
    }*/


?>