/****** Object:  Database [Manager_Control] ******/
CREATE DATABASE [Manager_Control] ON  PRIMARY 
( NAME = N'ManagerControl', FILENAME = N'I:\SQLServerData\Manager_Control.mdf' , SIZE = 78464KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'ManagerControl_log', FILENAME = N'H:\SQLServerData\Manager_Control_log.ldf' , SIZE = 34752KB , MAXSIZE = UNLIMITED, FILEGROWTH = 16384KB )
 COLLATE SQL_Latin1_General_CP1_CI_AS
GO
ALTER DATABASE [Manager_Control] SET COMPATIBILITY_LEVEL = 100
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [Manager_Control].[dbo].[sp_fulltext_database] @action = 'disable'
end
GO
ALTER DATABASE [Manager_Control] SET ANSI_NULL_DEFAULT ON 
GO
ALTER DATABASE [Manager_Control] SET ANSI_NULLS ON 
GO
ALTER DATABASE [Manager_Control] SET ANSI_PADDING ON 
GO
ALTER DATABASE [Manager_Control] SET ANSI_WARNINGS ON 
GO
ALTER DATABASE [Manager_Control] SET ARITHABORT ON 
GO
ALTER DATABASE [Manager_Control] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [Manager_Control] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [Manager_Control] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [Manager_Control] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [Manager_Control] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [Manager_Control] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [Manager_Control] SET CONCAT_NULL_YIELDS_NULL ON 
GO
ALTER DATABASE [Manager_Control] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [Manager_Control] SET QUOTED_IDENTIFIER ON 
GO
ALTER DATABASE [Manager_Control] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [Manager_Control] SET  DISABLE_BROKER 
GO
ALTER DATABASE [Manager_Control] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [Manager_Control] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [Manager_Control] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [Manager_Control] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [Manager_Control] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [Manager_Control] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [Manager_Control] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [Manager_Control] SET RECOVERY FULL 
GO
ALTER DATABASE [Manager_Control] SET  MULTI_USER 
GO
ALTER DATABASE [Manager_Control] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [Manager_Control] SET DB_CHAINING OFF 
GO
USE [Manager_Control]
GO
/****** Object:  User [D3J410] ******/
CREATE USER [D3J410] FOR LOGIN [PNL\D3J410] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [DMS_Guest] ******/
CREATE USER [DMS_Guest] FOR LOGIN [PNL\EMSL-Prism.Users.DMS_Guest]
GO
/****** Object:  User [DMS_User] ******/
CREATE USER [DMS_User] FOR LOGIN [PNL\EMSL-Prism.Users.DMS_User]
GO
/****** Object:  User [DMSReader] ******/
CREATE USER [DMSReader] FOR LOGIN [DMSReader] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [DMSWebUser] ******/
CREATE USER [DMSWebUser] FOR LOGIN [DMSWebUser] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [MTUser] ******/
CREATE USER [MTUser] FOR LOGIN [mtuser] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [proteinseqs\ftms] ******/
CREATE USER [proteinseqs\ftms] FOR LOGIN [PROTEINSEQS\ftms] WITH DEFAULT_SCHEMA=[proteinseqs\ftms]
GO
/****** Object:  User [Proteinseqs\msdadmin] ******/
CREATE USER [Proteinseqs\msdadmin] FOR LOGIN [Proteinseqs\msdadmin] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [RBAC-MgrConfig_Admin] ******/
CREATE USER [RBAC-MgrConfig_Admin] FOR LOGIN [PNL\EMSL-Prism.Users.DMS_MgrConfig_Admin]
GO
/****** Object:  User [svc-dms] ******/
CREATE USER [svc-dms] FOR LOGIN [PNL\svc-dms] WITH DEFAULT_SCHEMA=[dbo]
GO
GRANT CONNECT TO [D3J410] AS [dbo]
GO
GRANT CONNECT TO [DMS_Guest] AS [dbo]
GO
GRANT CONNECT TO [DMS_User] AS [dbo]
GO
GRANT CONNECT TO [DMSReader] AS [dbo]
GO
GRANT SHOWPLAN TO [DMSReader] AS [dbo]
GO
GRANT CONNECT TO [DMSWebUser] AS [dbo]
GO
GRANT SHOWPLAN TO [DMSWebUser] AS [dbo]
GO
GRANT CONNECT TO [MTUser] AS [dbo]
GO
GRANT SHOWPLAN TO [MTUser] AS [dbo]
GO
GRANT CONNECT TO [proteinseqs\ftms] AS [dbo]
GO
GRANT CONNECT TO [Proteinseqs\msdadmin] AS [dbo]
GO
GRANT CONNECT TO [RBAC-MgrConfig_Admin] AS [dbo]
GO
GRANT CONNECT TO [svc-dms] AS [dbo]
GO
ALTER DATABASE [Manager_Control] SET  READ_WRITE 
GO
