-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 16-07-2022 a las 02:31:06
-- Versión del servidor: 10.4.24-MariaDB
-- Versión de PHP: 8.1.6

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `fiesta`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `actualizar_precio_producto` (`n_cantidad` INT, `n_precio` DECIMAL(10,2), `codigo` INT)   BEGIN
		DECLARE nueva_existencia int;
		DECLARE nuevo_total decimal(10,2);
		DECLARE nuevo_precio decimal(10,2);

		DECLARE cant_actual int;
		DECLARE pre_actual decimal(10,2);

		DECLARE actual_existencia int;
		DECLARE actual_precio decimal(10,2);

		SELECT precio,existencia INTO actual_precio,actual_existencia FROM producto WHERE codproducto = codigo; 
		SET nueva_existencia = actual_existencia + n_cantidad; 
		SET nuevo_total = (actual_existencia * actual_precio) + (n_cantidad * n_precio);
		SET nuevo_precio = nuevo_total / nueva_existencia;
		
		UPDATE  producto SET existencia = nueva_existencia, precio = nuevo_precio WHERE codproducto = codigo;

		SELECT nueva_existencia,nuevo_precio;

	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_detalle_temp` (`codigo` INT, `cantidad` INT, `token_user` VARCHAR(50))   BEGIN  
    
    	DECLARE precio_actual decimal(10,2); 
        SELECT precio INTO precio_actual FROM producto WHERE codproducto = codigo;  
        
        INSERT INTO detalle_temp(token_user,codproducto,cantidad,precio_venta) VALUES(token_user, codigo, cantidad, precio_actual);
        
        SELECT tmp.correlativo, tmp.codproducto,p.descripcion, tmp.cantidad, tmp.precio_venta FROM detalle_temp tmp
        INNER JOIN producto p 
        ON tmp.codproducto = p.codproducto
        WHERE tmp.token_user = token_user;
        
	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `anular_factura` (`no_factura` INT)   BEGIN
	DECLARE existe_factura int;	
	DECLARE registros int;		
	DECLARE a int;			

	DECLARE cod_producto int;
	DECLARE cant_producto int;
	DECLARE existencia_actual int;
	DECLARE nueva_existencia int;
	
	
	SET existe_factura = (SELECT COUNT(*) FROM factura WHERE nofactura = no_factura and estatus = 1);

	
	IF existe_factura > 0 THEN		
	    CREATE TEMPORARY TABLE tbl_tmp(
		 id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
		 cod_prod BIGINT,
		 cant_prod int);
		 
		 SET a = 1;

		
		 SET registros = (SELECT COUNT(*) FROM detallefactura WHERE nofactura = no_factura);

		 IF registros > 0 THEN 
		     INSERT INTO tbl_tmp(cod_prod,cant_prod) SELECT codproducto,cantidad FROM detallefactura WHERE nofactura = no_factura;

		     WHILE a <= registros DO
			 SELECT cod_prod,cant_prod INTO cod_producto,cant_producto FROM tbl_tmp WHERE id = a;
			 SELECT existencia INTO existencia_actual FROM producto WHERE codproducto = cod_producto;	
			 SET nueva_existencia = existencia_actual + cant_producto;	
			 UPDATE producto SET existencia = nueva_existencia WHERE codproducto = cod_producto;		
			 
			 SET a=a+1; 	
			 
		     END WHILE; 

		     UPDATE factura SET estatus = 2 WHERE nofactura = no_factura;	 
		     DROP TABLE tbl_tmp;	 
		     SELECT * from factura WHERE nofactura = no_factura;             


		 END IF; 

	ELSE
	    SELECT 0 factura;
	END IF;

    END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `del_detalle_temp` (`id_detalle` INT, `token` VARCHAR(50))   BEGIN
    	DELETE FROM detalle_temp WHERE correlativo = id_detalle;
        
        SELECT tmp.correlativo, tmp.codproducto,p.descripcion,tmp.cantidad,tmp.precio_venta FROM detalle_temp tmp
        INNER JOIN producto p
        ON tmp.codproducto = p.codproducto
        WHERE tmp.token_user = token;
	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `procesar_venta` (`cod_usuario` INT, `cod_cliente` INT, `token` VARCHAR(50))   BEGIN
		DECLARE factura INT;	

		DECLARE registros INT;		
		DECLARE total DECIMAL(10,2);

		DECLARE nueva_existencia int;
		DECLARE existencia_actual int;

		DECLARE tmp_cod_producto int;
		DECLARE tmp_cant_producto int;
		DECLARE a INT;
		SET a = 1;

		CREATE TEMPORARY TABLE tbl_tmp_tokenuser(					
				id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,		
				cod_prod BIGINT,									
				cant_prod int);										
		SET registros = (SELECT COUNT(*) FROM detalle_temp WHERE token_user = token); 

		IF registros > 0 THEN 
			INSERT INTO tbl_tmp_tokenuser(cod_prod,cant_prod) SELECT codproducto,cantidad FROM detalle_temp WHERE token_user = token;

			INSERT INTO factura(usuario,codcliente) VALUES(cod_usuario,cod_cliente);
			SET factura = LAST_INSERT_ID();

			INSERT INTO detallefactura(nofactura,codproducto,cantidad,precio_venta) SELECT (factura) as nofactura, codproducto,cantidad,precio_venta FROM detalle_temp
			WHERE token_user = token;

			WHILE a <= registros DO
			    SELECT cod_prod,cant_prod INTO tmp_cod_producto,tmp_cant_producto FROM tbl_tmp_tokenuser WHERE id = a;
			    SELECT existencia INTO existencia_actual FROM producto WHERE codproducto = tmp_cod_producto;

			    SET nueva_existencia = existencia_actual - tmp_cant_producto;
			    UPDATE producto SET existencia = nueva_existencia WHERE codproducto = tmp_cod_producto;

			    SET a=a+1;
				
			END WHILE;

			SET total = (SELECT SUM(cantidad * precio_venta) FROM detalle_temp WHERE token_user = token);
			UPDATE factura SET totalfactura = total WHERE nofactura = factura;
			DELETE FROM detalle_temp WHERE token_user = token;
			TRUNCATE TABLE tbl_tmp_tokenuser;
			SELECT * FROM factura WHERE nofactura = factura;
		ELSE 
		    SELECT 0;

		END IF; 
	END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cliente`
--

CREATE TABLE `cliente` (
  `idcliente` int(11) NOT NULL,
  `nit` int(11) DEFAULT NULL,
  `nombre` varchar(80) DEFAULT NULL,
  `telefono` bigint(20) DEFAULT NULL,
  `direccion` text DEFAULT NULL,
  `dateadd` datetime NOT NULL DEFAULT current_timestamp(),
  `usuario_id` int(11) NOT NULL,
  `estatus` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `cliente`
--

INSERT INTO `cliente` (`idcliente`, `nit`, `nombre`, `telefono`, `direccion`, `dateadd`, `usuario_id`, `estatus`) VALUES
(1, 0, 'CF', 6446148, 'Avenida siempre viva 123', '2021-05-25 18:56:17', 1, 1),
(2, 106532187, 'Fernando Quiroga', 8965, 'Piedecuesta Barrio Landinez', '2021-05-26 17:38:15', 1, 1),
(3, 63591254, 'Fabio Quintanilla', 3219037452, 'cañaveral ', '2021-05-26 17:38:48', 1, 1),
(4, 912365874, 'Mario Guzman', 3158745620, 'calle1 av 23-08', '2021-05-26 17:39:48', 1, 1),
(5, 1085651235, 'Fernanda Oviedo', 2147483647, 'calle Medellin av paisa', '2021-05-26 18:06:45', 1, 1),
(6, 1098753642, 'Oscar Ferreira', 3218520167, 'Barrio mutis', '2021-05-29 16:15:12', 1, 1),
(7, 63482759, 'German Sierra', 6558742, 'Calle 41 cra 16 centro', '2021-06-20 01:14:42', 1, 1),
(8, 953264200, 'Eduardo Uribe', 3152698754, 'Balcones de Cabecera ', '2021-06-20 01:15:19', 1, 1),
(9, 105632147, 'Cesar Aguilar', 3102587456, 'Altos de la Cumbre ', '2021-06-20 01:15:54', 1, 1),
(10, 1098721964, 'Roberto Cardenas', 3215632480, 'Barrio Santander', '2022-03-29 18:19:20', 1, 1),
(11, 1098721942, 'Roberto Cardales', 31856479520, 'Barrio Alvarez', '2022-03-29 18:19:33', 1, 1),
(12, 123458762, 'Julio Pineda', 3218654209, 'Bogota Barrio Normandia ', '2022-03-29 19:01:57', 1, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `configuracion`
--

CREATE TABLE `configuracion` (
  `id` bigint(20) NOT NULL,
  `nit` varchar(20) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `razon_social` varchar(100) NOT NULL,
  `telefono` bigint(20) NOT NULL,
  `email` varchar(200) NOT NULL,
  `direccion` text NOT NULL,
  `iva` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `configuracion`
--

INSERT INTO `configuracion` (`id`, `nit`, `nombre`, `razon_social`, `telefono`, `email`, `direccion`, `iva`) VALUES
(1, '8020018901', 'SoftNup', '', 6516500, 'notificacionessoft@softnup.com', 'Lagos del Cacique Bucaramanga', '12.00');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detallefactura`
--

CREATE TABLE `detallefactura` (
  `correlativo` bigint(11) NOT NULL,
  `nofactura` bigint(11) DEFAULT NULL,
  `codproducto` int(11) DEFAULT NULL,
  `cantidad` int(11) DEFAULT NULL,
  `precio_venta` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `detallefactura`
--

INSERT INTO `detallefactura` (`correlativo`, `nofactura`, `codproducto`, `cantidad`, `precio_venta`) VALUES
(1, 1, 1, 1, '150000.00'),
(2, 1, 2, 1, '750000.00'),
(3, 1, 3, 1, '500000.00'),
(4, 1, 4, 1, '500000.00'),
(5, 1, 5, 1, '100000.00'),
(8, 2, 1, 1, '150000.00'),
(9, 2, 2, 1, '750000.00'),
(10, 2, 3, 1, '500000.00'),
(11, 2, 4, 1, '500000.00'),
(12, 2, 5, 1, '100000.00'),
(13, 3, 2, 1, '750000.00'),
(14, 3, 3, 2, '500000.00'),
(15, 3, 5, 1, '100000.00'),
(16, 4, 9, 1, '400000.00'),
(17, 4, 16, 1, '300000.00'),
(19, 5, 14, 1, '580000.00'),
(20, 5, 13, 1, '900000.00'),
(22, 6, 20, 1, '1500000.00'),
(23, 6, 21, 1, '860000.06'),
(24, 7, 2, 1, '750000.00'),
(25, 7, 1, 1, '150000.00'),
(26, 8, 8, 5, '600000.00'),
(27, 8, 2, 3, '750000.00'),
(28, 8, 4, 5, '500000.00'),
(29, 9, 1, 1, '150000.00'),
(30, 9, 2, 2, '750000.00');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_temp`
--

CREATE TABLE `detalle_temp` (
  `correlativo` int(11) NOT NULL,
  `token_user` varchar(50) NOT NULL,
  `codproducto` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `precio_venta` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `entradas`
--

CREATE TABLE `entradas` (
  `correlativo` int(11) NOT NULL,
  `codproducto` int(11) NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `cantidad` int(11) NOT NULL,
  `precio` decimal(10,2) NOT NULL,
  `usuario_id` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `entradas`
--

INSERT INTO `entradas` (`correlativo`, `codproducto`, `fecha`, `cantidad`, `precio`, `usuario_id`) VALUES
(1, 1, '2021-07-12 22:41:03', 150, '110.00', 1),
(2, 2, '2021-07-13 17:19:04', 9, '5000000.00', 1),
(3, 3, '2021-07-13 17:20:35', 9, '5000000.00', 1),
(4, 4, '2021-07-13 17:20:38', 9, '5000000.00', 1),
(5, 5, '2021-07-13 17:21:10', 5, '2000000.00', 1),
(6, 6, '2021-07-14 10:33:33', 5, '2000.00', 1),
(7, 7, '2021-07-14 11:27:58', 5, '2000.00', 1),
(8, 8, '2021-07-14 11:28:03', 5, '2000.00', 1),
(9, 9, '2021-07-14 11:29:11', 6, '1500000.00', 1),
(10, 10, '2021-07-14 11:35:15', 6, '1500000.00', 1),
(11, 12, '2021-07-14 11:48:41', 8, '600000.00', 1),
(12, 13, '2021-07-14 12:45:26', 9, '900000.00', 1),
(13, 14, '2021-07-14 15:01:08', 32, '16000.00', 1),
(14, 15, '2021-07-14 19:51:39', 26, '400000.00', 1),
(15, 16, '2021-07-22 19:09:05', 10, '200.00', 1),
(16, 17, '2021-07-22 19:10:58', 60, '55555.00', 1),
(17, 18, '2022-02-19 17:07:28', 16, '2000000.00', 1),
(18, 19, '2022-02-19 17:13:42', 10, '1500000.00', 1),
(19, 20, '2022-02-21 16:08:41', 6, '1500000.00', 1),
(20, 21, '2022-02-21 23:13:31', 0, '117.06', 1),
(21, 1, '2022-03-02 18:50:46', 5, '150000.00', 1),
(22, 1, '2022-03-02 19:10:48', 10, '750000.00', 1),
(23, 2, '2022-03-02 19:11:42', 1, '750000.00', 1),
(24, 3, '2022-03-02 19:13:14', 1, '500000.00', 1),
(25, 1, '2022-03-02 19:14:40', 1, '150000.00', 1),
(26, 4, '2022-03-02 19:25:36', 1, '500000.00', 1),
(27, 5, '2022-03-02 19:27:21', 2, '100000.00', 1),
(28, 1, '2022-07-05 18:58:58', 91, '150000.00', 1),
(29, 2, '2022-07-05 18:59:10', 92, '750000.00', 1),
(30, 3, '2022-07-05 18:59:20', 93, '500000.00', 1),
(31, 4, '2022-07-05 19:00:26', 91, '500000.00', 1),
(32, 5, '2022-07-05 19:00:36', 95, '100000.00', 1),
(33, 6, '2022-07-05 19:00:55', 95, '200000.00', 1),
(34, 7, '2022-07-05 19:01:05', 95, '900000.00', 1),
(35, 8, '2022-07-05 19:01:16', 95, '600000.00', 1),
(36, 9, '2022-07-05 19:01:25', 95, '400000.00', 1),
(37, 10, '2022-07-05 19:01:35', 94, '150000.00', 1),
(38, 12, '2022-07-05 19:01:47', 92, '260000.00', 1),
(39, 13, '2022-07-05 19:01:56', 92, '900000.00', 1),
(40, 14, '2022-07-05 19:02:09', 69, '580000.00', 1),
(41, 15, '2022-07-05 19:02:24', 74, '400000.00', 1),
(42, 16, '2022-07-05 19:02:34', 91, '300000.00', 1),
(43, 17, '2022-07-05 19:02:45', 40, '90000.00', 1),
(44, 18, '2022-07-05 19:02:56', 84, '210000.00', 1),
(45, 19, '2022-07-05 19:03:06', 90, '1500000.00', 1),
(46, 20, '2022-07-05 19:03:17', 95, '1500000.00', 1),
(47, 21, '2022-07-05 19:03:29', 100, '210000.00', 1),
(48, 21, '2022-07-05 19:03:44', 1, '1000000.00', 1),
(49, 1, '2022-07-11 23:07:32', 1, '150000.00', 1),
(50, 2, '2022-07-11 23:07:46', 1, '750000.00', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `factura`
--

CREATE TABLE `factura` (
  `nofactura` bigint(11) NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `usuario` int(11) DEFAULT NULL,
  `codcliente` int(11) DEFAULT NULL,
  `totalfactura` decimal(10,2) DEFAULT NULL,
  `estatus` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `factura`
--

INSERT INTO `factura` (`nofactura`, `fecha`, `usuario`, `codcliente`, `totalfactura`, `estatus`) VALUES
(1, '2022-06-30 22:52:12', 1, 6, NULL, 1),
(2, '2022-06-30 22:53:57', 1, 6, '2000000.00', 1),
(3, '2022-07-05 18:51:32', 1, 5, '1850000.00', 1),
(4, '2022-07-05 18:54:49', 1, 1, '700000.00', 1),
(5, '2022-07-05 18:55:46', 1, 1, '1480000.00', 1),
(6, '2022-07-05 18:57:43', 1, 1, '2360000.06', 1),
(7, '2022-07-07 09:01:54', 1, 3, '900000.00', 1),
(8, '2022-07-11 23:03:22', 1, 12, '7750000.00', 1),
(9, '2022-07-13 00:46:52', 1, 12, '1650000.00', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `producto`
--

CREATE TABLE `producto` (
  `codproducto` int(11) NOT NULL,
  `descripcion` varchar(100) DEFAULT NULL,
  `proveedor` int(11) DEFAULT NULL,
  `precio` decimal(10,2) DEFAULT NULL,
  `existencia` int(11) DEFAULT NULL,
  `date_add` datetime NOT NULL DEFAULT current_timestamp(),
  `usuario_id` int(11) NOT NULL,
  `estatus` int(11) NOT NULL DEFAULT 1,
  `foto` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `producto`
--

INSERT INTO `producto` (`codproducto`, `descripcion`, `proveedor`, `precio`, `existencia`, `date_add`, `usuario_id`, `estatus`, `foto`) VALUES
(1, 'Software Holded ', 7, '150000.00', 112, '2021-07-12 22:41:03', 1, 1, 'img_4564a14e893d94b87308f4e7d022c5fc.jpg'),
(2, 'Software Gescola', 2, '750000.00', 117, '2021-07-13 17:19:04', 1, 1, 'img_a930008dcb67035b1ed45edc11ffeced.jpg'),
(3, 'Software Phidias', 15, '500000.00', 121, '2021-07-13 17:20:35', 1, 1, 'img_c872e762445f6e0d91a922aca8ebe0b8.jpg'),
(4, 'Software Aula1', 2, '500000.00', 111, '2021-07-13 17:20:38', 1, 1, 'img_0f4b3d3cf515daeeb82c29ea5f7acf14.jpg'),
(5, 'Software GQdalya', 7, '100000.00', 116, '2021-07-13 17:21:10', 1, 1, 'img_3c1e1d3ee7bb1cd0904e3e7868c6bb89.jpg'),
(6, 'Software Clickedu', 4, '200000.00', 100, '2021-07-14 10:33:33', 1, 1, 'img_c8f8b0c44bd031c38fbcdf12182a9396.jpg'),
(7, 'Software ClassLink', 14, '900000.00', 100, '2021-07-14 11:27:58', 1, 1, 'img_ec8aac555fbe4a09fb240e8cf4bd58cc.jpg'),
(8, 'Software iesfácil', 3, '600000.00', 100, '2021-07-14 11:28:03', 1, 1, 'img_c872e762445f6e0d91a922aca8ebe0b8.jpg'),
(9, 'Software Educanlia', 16, '400000.00', 101, '2021-07-14 11:29:11', 1, 1, 'img_7bad86fd5dda84bb1c439680af57ebb8.jpg'),
(10, 'Software ApliAula', 1, '150000.00', 100, '2021-07-14 11:35:15', 1, 1, 'img_37a63949bc6b32b36dbbfcf8fa9ef4c6.jpg'),
(12, 'Software GoomBook', 17, '260000.00', 100, '2021-07-14 11:48:41', 1, 1, 'img_0b5eb1a16e026a12740bb6a29f6aa65f.jpg'),
(13, 'Software Classlife', 10, '900000.00', 101, '2021-07-14 12:45:26', 1, 1, 'img_c8f8b0c44bd031c38fbcdf12182a9396.jpg'),
(14, 'Software Alexia', 13, '580000.00', 101, '2021-07-14 15:01:08', 1, 1, 'img_5dc53ccdb08aa024e4fe604ec84d2fb9.jpg'),
(15, 'Software Factusol', 6, '400000.00', 100, '2021-07-14 19:51:39', 1, 1, 'img_4d20c9680a8ce04e99dc7304af15a4ce.jpg'),
(16, 'Software Alegra', 8, '300000.00', 101, '2021-07-22 19:09:05', 1, 1, 'img_d91afeb374fdc06d209f065dbee1aa71.jpg'),
(17, 'Software iSpring Suite', 12, '90000.00', 100, '2021-07-22 19:10:58', 1, 1, 'img_858dad10a9382ceb74732b5232c9b8c1.jpg'),
(18, 'Software ActivePresenter', 11, '210000.00', 100, '2022-02-19 17:07:28', 1, 1, 'img_929b440aacf7b20f5aa753013aeb9f40.jpg'),
(19, 'Scribus Software Fácil', 17, '1000000.00', 100, '2022-02-19 17:13:42', 1, 1, 'img_f3474abadde40d1d19d1fd7c6dc99739.jpg'),
(20, 'TradeGecko', 16, '1000000.00', 100, '2022-02-21 16:08:41', 1, 1, 'img_3037fb6ef20498834e816124040fa282.jpg'),
(21, 'Software FlashBack', 9, '211400.00', 100, '2022-02-21 23:13:31', 1, 1, 'img_282568f751e4850ea34933a9e12db8ac.jpg');

--
-- Disparadores `producto`
--
DELIMITER $$
CREATE TRIGGER `entradas_A_I` AFTER INSERT ON `producto` FOR EACH ROW BEGIN
		INSERT INTO entradas(codproducto,cantidad,precio,usuario_id)
        VALUES(new.codproducto,new.existencia,new.precio,new.usuario_id);
    END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proveedor`
--

CREATE TABLE `proveedor` (
  `codproveedor` int(11) NOT NULL,
  `proveedor` varchar(100) DEFAULT NULL,
  `contacto` varchar(100) DEFAULT NULL,
  `telefono` bigint(11) DEFAULT NULL,
  `direccion` text DEFAULT NULL,
  `date_add` datetime NOT NULL DEFAULT current_timestamp(),
  `usuario_id` int(11) NOT NULL,
  `estatus` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `proveedor`
--

INSERT INTO `proveedor` (`codproveedor`, `proveedor`, `contacto`, `telefono`, `direccion`, `date_add`, `usuario_id`, `estatus`) VALUES
(1, 'Robosoft', 'Claudia Rosales', 3115248955, 'Avenida las Americas-Bogota', '2021-07-09 20:34:26', 0, 1),
(2, 'Appsmart', 'Jorge Herrera', 3504862540, ' Alto de Patios Bogotá ', '2021-07-09 20:34:26', 0, 1),
(3, 'Microsenses', 'Julio Estrada', 3219024630, 'Avenida 5 Piedecuesta', '2021-07-09 20:34:26', 0, 1),
(4, 'DellSoft Compani', 'Roberto Estrada', 3002785103, 'Floridablanca Santander', '2021-07-09 20:34:26', 0, 1),
(5, 'VirusNot S.A', 'Elena Franco Morales', 3215402183, '5ta. Avenida Zona 4 Bucaramanga', '2021-07-09 20:34:26', 0, 1),
(6, 'Softter', 'Fernando Guerra', 3008710269, 'Calzada La Paz, Piedecuesta ', '2021-07-09 20:34:26', 0, 1),
(7, 'Ciber Desarrollos S.A', 'Ruben Perez', 3005978201, 'La Victoria Bucaramanga', '2021-07-09 20:34:26', 0, 1),
(8, 'Tech & Fun', 'Julieta Contreras', 3207105493, 'Cañaveral, la Florida ', '2021-07-09 20:34:26', 0, 1),
(9, 'ValTech', 'Felix Arnoldo Rojas', 3162597308, 'Avenida las Americas Bogota', '2021-07-09 20:34:26', 0, 1),
(10, 'Security Apps', 'Oscar Maldonado', 3185479016, 'Quebradaseca-Bucaramanga', '2021-07-09 20:34:26', 0, 1),
(11, 'UFO Development', 'Angel Cardona', 3108472106, '5ta. calle zona 4 Floridablanca', '2021-07-09 20:34:26', 0, 1),
(12, 'TecnoSoft', 'Andres Pedraza', 30187205668, 'Zona Franca - Florida', '2021-07-09 23:22:56', 1, 1),
(13, 'SoftSystem', 'Armando Lopez', 3215874569, 'Centro empresarial-Cabecera', '2021-07-09 23:40:08', 1, 1),
(14, 'MarketSoft', 'Leonardo Manrique', 3215620348, 'Hilton-Cabecera', '2021-07-11 15:48:04', 10, 1),
(15, 'Android-Apps', 'Carlos Jaimes', 3185201379, 'Lagos del Cacique', '2021-07-13 15:41:03', 1, 1),
(16, 'NuñezSoft', 'Fabian Andrés Núñez Pinzón ', 3156854453, 'Metropolitan Business Park - Cabecera', '2021-07-22 19:21:14', 1, 1),
(17, 'ScribusSoft', 'Manuel Belandia', 3158475602, 'Zona Franca', '2022-02-19 17:06:35', 1, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rol`
--

CREATE TABLE `rol` (
  `idrol` int(11) NOT NULL,
  `rol` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `rol`
--

INSERT INTO `rol` (`idrol`, `rol`) VALUES
(1, 'Administrador'),
(2, 'Supervisor'),
(3, 'Vendedor');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuario`
--

CREATE TABLE `usuario` (
  `idusuario` int(11) NOT NULL,
  `nombre` varchar(50) DEFAULT NULL,
  `correo` varchar(100) DEFAULT NULL,
  `usuario` varchar(15) DEFAULT NULL,
  `clave` varchar(100) DEFAULT NULL,
  `rol` int(11) DEFAULT NULL,
  `estatus` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `usuario`
--

INSERT INTO `usuario` (`idusuario`, `nombre`, `correo`, `usuario`, `clave`, `rol`, `estatus`) VALUES
(1, 'Fabian Nuñez', 'fabnupi023@gmail.com', 'admin', '202cb962ac59075b964b07152d234b70', 1, 1),
(8, 'Wilson Pinzon', 'wpinzon@uis.edu.co', 'wpinzon', '202cb962ac59075b964b07152d234b70', 2, 1),
(9, 'Abelardo Nuñez', 'anunez@outlook.com', 'anunez', '202cb962ac59075b964b07152d234b70', 1, 1),
(10, 'Diego Peña', 'dpena@yahoo.com', 'dpena', '202cb962ac59075b964b07152d234b70', 2, 1),
(11, 'Margarita Hurtado', 'mhurtado@gmail.com', 'mhurtado', '81dc9bdb52d04dc20036dbd8313ed055', 3, 1),
(12, 'Andrea Santos', 'asantos@uis.edu.co', 'asantos', '202cb962ac59075b964b07152d234b70', 3, 1),
(13, 'Cindy Aza', 'caza@yahoo.com', 'caza', '202cb962ac59075b964b07152d234b70', 3, 1),
(14, 'Jose Gonzales', 'jgonzales@hardvard.edu.co', 'jgonzales', '202cb962ac59075b964b07152d234b70', 2, 1),
(15, 'Laura Alvarez', 'lalvarez@gmail.com', 'lalvarez', '202cb962ac59075b964b07152d234b70', 3, 1),
(16, 'Juliana Arias', 'jarias@usta.edu.co', 'jarias', '202cb962ac59075b964b07152d234b70', 2, 1),
(17, 'Karol Saavedra', 'ksaavedra@gmail.com', 'ksaavedra', '202cb962ac59075b964b07152d234b70', 3, 1),
(18, 'Oscar Pedraza', 'opedraza@yahoo.com', 'opedraza', '202cb962ac59075b964b07152d234b70', 3, 1),
(19, 'Julio Quintero', 'jquintero@hotmail.com', 'jquintero', '202cb962ac59075b964b07152d234b70', 2, 1),
(20, 'Yessica Guzman', 'yguzman@gmail.com', 'yguzman', '202cb962ac59075b964b07152d234b70', 2, 1),
(21, 'Karen Bravo', 'kbravo@outlook.com', 'kbravo', '202cb962ac59075b964b07152d234b70', 2, 1),
(22, 'Daniela Ordoñez', 'dordonez@mail.com', 'dordonez', '202cb962ac59075b964b07152d234b70', 3, 1),
(23, 'Jaime Puentes', 'jpuentes@mail.com', 'jpuentes', '202cb962ac59075b964b07152d234b70', 1, 1),
(24, 'Vanessa Guerrero', 'vguerrero@gmail.com', 'vguerrero', '202cb962ac59075b964b07152d234b70', 1, 1),
(25, 'Marvin Gate', 'mgate@outlook.com', 'mgate', '202cb962ac59075b964b07152d234b70', 2, 1);

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `cliente`
--
ALTER TABLE `cliente`
  ADD PRIMARY KEY (`idcliente`),
  ADD KEY `usuario_id` (`usuario_id`);

--
-- Indices de la tabla `configuracion`
--
ALTER TABLE `configuracion`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `detallefactura`
--
ALTER TABLE `detallefactura`
  ADD PRIMARY KEY (`correlativo`),
  ADD KEY `codproducto` (`codproducto`),
  ADD KEY `nofactura` (`nofactura`);

--
-- Indices de la tabla `detalle_temp`
--
ALTER TABLE `detalle_temp`
  ADD PRIMARY KEY (`correlativo`),
  ADD KEY `nofactura` (`token_user`),
  ADD KEY `codproducto` (`codproducto`);

--
-- Indices de la tabla `entradas`
--
ALTER TABLE `entradas`
  ADD PRIMARY KEY (`correlativo`),
  ADD KEY `codproducto` (`codproducto`),
  ADD KEY `usuario_id` (`usuario_id`);

--
-- Indices de la tabla `factura`
--
ALTER TABLE `factura`
  ADD PRIMARY KEY (`nofactura`),
  ADD KEY `usuario` (`usuario`),
  ADD KEY `codcliente` (`codcliente`);

--
-- Indices de la tabla `producto`
--
ALTER TABLE `producto`
  ADD PRIMARY KEY (`codproducto`),
  ADD KEY `proveedor` (`proveedor`),
  ADD KEY `usuario_id` (`usuario_id`);

--
-- Indices de la tabla `proveedor`
--
ALTER TABLE `proveedor`
  ADD PRIMARY KEY (`codproveedor`),
  ADD KEY `usuario_id` (`usuario_id`);

--
-- Indices de la tabla `rol`
--
ALTER TABLE `rol`
  ADD PRIMARY KEY (`idrol`);

--
-- Indices de la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD PRIMARY KEY (`idusuario`),
  ADD KEY `rol` (`rol`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `cliente`
--
ALTER TABLE `cliente`
  MODIFY `idcliente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT de la tabla `configuracion`
--
ALTER TABLE `configuracion`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `detallefactura`
--
ALTER TABLE `detallefactura`
  MODIFY `correlativo` bigint(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- AUTO_INCREMENT de la tabla `detalle_temp`
--
ALTER TABLE `detalle_temp`
  MODIFY `correlativo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=55;

--
-- AUTO_INCREMENT de la tabla `entradas`
--
ALTER TABLE `entradas`
  MODIFY `correlativo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=51;

--
-- AUTO_INCREMENT de la tabla `factura`
--
ALTER TABLE `factura`
  MODIFY `nofactura` bigint(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT de la tabla `producto`
--
ALTER TABLE `producto`
  MODIFY `codproducto` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT de la tabla `proveedor`
--
ALTER TABLE `proveedor`
  MODIFY `codproveedor` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT de la tabla `rol`
--
ALTER TABLE `rol`
  MODIFY `idrol` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `usuario`
--
ALTER TABLE `usuario`
  MODIFY `idusuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `cliente`
--
ALTER TABLE `cliente`
  ADD CONSTRAINT `cliente_ibfk_1` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`idusuario`);

--
-- Filtros para la tabla `detallefactura`
--
ALTER TABLE `detallefactura`
  ADD CONSTRAINT `detallefactura_ibfk_1` FOREIGN KEY (`nofactura`) REFERENCES `factura` (`nofactura`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `detallefactura_ibfk_2` FOREIGN KEY (`codproducto`) REFERENCES `producto` (`codproducto`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `detalle_temp`
--
ALTER TABLE `detalle_temp`
  ADD CONSTRAINT `detalle_temp_ibfk_2` FOREIGN KEY (`codproducto`) REFERENCES `producto` (`codproducto`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `entradas`
--
ALTER TABLE `entradas`
  ADD CONSTRAINT `entradas_ibfk_1` FOREIGN KEY (`codproducto`) REFERENCES `producto` (`codproducto`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `factura`
--
ALTER TABLE `factura`
  ADD CONSTRAINT `factura_ibfk_1` FOREIGN KEY (`usuario`) REFERENCES `usuario` (`idusuario`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `factura_ibfk_2` FOREIGN KEY (`codcliente`) REFERENCES `cliente` (`idcliente`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `producto`
--
ALTER TABLE `producto`
  ADD CONSTRAINT `producto_ibfk_1` FOREIGN KEY (`proveedor`) REFERENCES `proveedor` (`codproveedor`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `producto_ibfk_2` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`idusuario`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD CONSTRAINT `usuario_ibfk_1` FOREIGN KEY (`rol`) REFERENCES `rol` (`idrol`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
