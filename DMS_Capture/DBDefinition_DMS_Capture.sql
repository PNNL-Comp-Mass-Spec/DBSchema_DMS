/****** Object:  Database [DMS_Capture] ******/
CREATE DATABASE [DMS_Capture] ON  PRIMARY 
( NAME = N'DMS_Capture', FILENAME = N'H:\SQLServerData\DMS_Capture.mdf' , SIZE = 4086400KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'DMS_Capture_log', FILENAME = N'G:\SQLServerData\DMS_Capture_log.ldf' , SIZE = 64960KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
 COLLATE SQL_Latin1_General_CP1_CI_AS
GO
ALTER DATABASE [DMS_Capture] SET COMPATIBILITY_LEVEL = 100
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [DMS_Capture].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [DMS_Capture] SET ANSI_NULL_DEFAULT ON 
GO
ALTER DATABASE [DMS_Capture] SET ANSI_NULLS ON 
GO
ALTER DATABASE [DMS_Capture] SET ANSI_PADDING ON 
GO
ALTER DATABASE [DMS_Capture] SET ANSI_WARNINGS ON 
GO
ALTER DATABASE [DMS_Capture] SET ARITHABORT ON 
GO
ALTER DATABASE [DMS_Capture] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [DMS_Capture] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [DMS_Capture] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [DMS_Capture] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [DMS_Capture] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [DMS_Capture] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [DMS_Capture] SET CONCAT_NULL_YIELDS_NULL ON 
GO
ALTER DATABASE [DMS_Capture] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [DMS_Capture] SET QUOTED_IDENTIFIER ON 
GO
ALTER DATABASE [DMS_Capture] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [DMS_Capture] SET  DISABLE_BROKER 
GO
ALTER DATABASE [DMS_Capture] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [DMS_Capture] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [DMS_Capture] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [DMS_Capture] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [DMS_Capture] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [DMS_Capture] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [DMS_Capture] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [DMS_Capture] SET RECOVERY FULL 
GO
ALTER DATABASE [DMS_Capture] SET  MULTI_USER 
GO
ALTER DATABASE [DMS_Capture] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [DMS_Capture] SET DB_CHAINING OFF 
GO
USE [DMS_Capture]
GO
/****** Object:  User [DMSReader] ******/
CREATE USER [DMSReader] FOR LOGIN [DMSReader] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [DMSWebUser] ******/
CREATE USER [DMSWebUser] FOR LOGIN [DMSWebUser] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [pnl\d3m578] ******/
CREATE USER [pnl\d3m578] FOR LOGIN [PNL\D3M578] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [PNL\D3M580] ******/
CREATE USER [PNL\D3M580] FOR LOGIN [PNL\D3M580] WITH DEFAULT_SCHEMA=[PNL\D3M580]
GO
/****** Object:  User [pnl\D3Y513] ******/
CREATE USER [pnl\D3Y513] FOR LOGIN [PNL\D3Y513] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [RBAC-DMS_User] ******/
CREATE USER [RBAC-DMS_User] FOR LOGIN [PNL\EMSL-Prism.Users.DMS_User]
GO
/****** Object:  User [svc-dms] ******/
CREATE USER [svc-dms] FOR LOGIN [PNL\svc-dms] WITH DEFAULT_SCHEMA=[dbo]
GO
GRANT CONNECT TO [DMSReader] AS [dbo]
GO
GRANT SHOWPLAN TO [DMSReader] AS [dbo]
GO
GRANT CONNECT TO [DMSWebUser] AS [dbo]
GO
GRANT SHOWPLAN TO [DMSWebUser] AS [dbo]
GO
GRANT CONNECT TO [pnl\d3m578] AS [dbo]
GO
GRANT CONNECT TO [pnl\D3Y513] AS [dbo]
GO
GRANT CONNECT TO [RBAC-DMS_User] AS [dbo]
GO
GRANT CONNECT TO [svc-dms] AS [dbo]
GO
ALTER DATABASE [DMS_Capture] SET  READ_WRITE 
GO
