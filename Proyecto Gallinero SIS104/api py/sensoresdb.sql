-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 24-11-2025 a las 02:12:29
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `sensoresdb`
--

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `datos_sensor`
--

CREATE TABLE `datos_sensor` (
  `id` int(11) NOT NULL,
  `fecha` timestamp NOT NULL DEFAULT current_timestamp(),
  `temperatura` float NOT NULL,
  `humedad` float NOT NULL,
  `nivel_agua` int(11) NOT NULL,
  `bomba_estado` tinyint(1) NOT NULL,
  `ventilador_estado` tinyint(1) NOT NULL,
  `nivel_comida` int(11) NOT NULL,
  `luces_estado` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `datos_sensor`
--

INSERT INTO `datos_sensor` (`id`, `fecha`, `temperatura`, `humedad`, `nivel_agua`, `bomba_estado`, `ventilador_estado`, `nivel_comida`, `luces_estado`) VALUES
(760, '2025-11-23 20:22:02', 23.4, 32, 400, 1, 0, 35, 0),
(761, '2025-11-18 19:15:28', 23.4, 32, 36, 1, 0, 35, 0),
(762, '2025-11-18 19:15:30', 23.4, 32, 34, 1, 0, 35, 0);

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `datos_sensor`
--
ALTER TABLE `datos_sensor`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `datos_sensor`
--
ALTER TABLE `datos_sensor`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=763;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
