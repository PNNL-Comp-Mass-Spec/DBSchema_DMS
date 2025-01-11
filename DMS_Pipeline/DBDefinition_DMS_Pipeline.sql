/****** Object:  Database [DMS_Pipeline] ******/
CREATE DATABASE [DMS_Pipeline]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'DMS_Pipeline_T3', FILENAME = N'J:\SQLServerData\DMS_Pipeline.mdf' , SIZE = 4440128KB , MAXSIZE = UNLIMITED, FILEGROWTH = 262144KB )
 LOG ON 
( NAME = N'DMS_Pipeline_T3_log', FILENAME = N'H:\SQLServerData\DMS_Pipeline_log.ldf' , SIZE = 3894400KB , MAXSIZE = 2048GB , FILEGROWTH = 131072KB )
 COLLATE SQL_Latin1_General_CP1_CI_AS
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [DMS_Pipeline].[dbo].[sp_fulltext_database] @action = 'disable'
end
GO
ALTER DATABASE [DMS_Pipeline] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [DMS_Pipeline] SET ANSI_NULLS ON 
GO
ALTER DATABASE [DMS_Pipeline] SET ANSI_PADDING ON 
GO
ALTER DATABASE [DMS_Pipeline] SET ANSI_WARNINGS ON 
GO
ALTER DATABASE [DMS_Pipeline] SET ARITHABORT ON 
GO
ALTER DATABASE [DMS_Pipeline] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [DMS_Pipeline] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [DMS_Pipeline] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [DMS_Pipeline] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [DMS_Pipeline] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [DMS_Pipeline] SET CONCAT_NULL_YIELDS_NULL ON 
GO
ALTER DATABASE [DMS_Pipeline] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [DMS_Pipeline] SET QUOTED_IDENTIFIER ON 
GO
ALTER DATABASE [DMS_Pipeline] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [DMS_Pipeline] SET  DISABLE_BROKER 
GO
ALTER DATABASE [DMS_Pipeline] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [DMS_Pipeline] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [DMS_Pipeline] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [DMS_Pipeline] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [DMS_Pipeline] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [DMS_Pipeline] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [DMS_Pipeline] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [DMS_Pipeline] SET RECOVERY FULL 
GO
ALTER DATABASE [DMS_Pipeline] SET  MULTI_USER 
GO
ALTER DATABASE [DMS_Pipeline] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [DMS_Pipeline] SET DB_CHAINING OFF 
GO
ALTER DATABASE [DMS_Pipeline] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [DMS_Pipeline] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
ALTER DATABASE [DMS_Pipeline] SET DELAYED_DURABILITY = DISABLED 
GO
USE [DMS_Pipeline]
GO
/****** Object:  User [DMSReader] ******/
CREATE USER [DMSReader] FOR LOGIN [DMSReader] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [DMSWebUser] ******/
CREATE USER [DMSWebUser] FOR LOGIN [DMSWebUser] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [GIGASAX\ftms] ******/
CREATE USER [GIGASAX\ftms] FOR LOGIN [GIGASAX\ftms] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [GIGASAX\msdadmin] ******/
CREATE USER [GIGASAX\msdadmin] FOR LOGIN [GIGASAX\msdadmin] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [NT AUTHORITY\SYSTEM] ******/
CREATE USER [NT AUTHORITY\SYSTEM] FOR LOGIN [NT AUTHORITY\SYSTEM] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [PNL\D3L243] ******/
CREATE USER [PNL\D3L243] FOR LOGIN [PNL\D3L243] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [PNL\D3M578] ******/
CREATE USER [PNL\D3M578] FOR LOGIN [PNL\D3M578] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [PNL\D3M580] ******/
CREATE USER [PNL\D3M580] FOR LOGIN [PNL\D3M580] WITH DEFAULT_SCHEMA=[PNL\D3M580]
GO
/****** Object:  User [pnl\gibb166] ******/
CREATE USER [pnl\gibb166] FOR LOGIN [PNL\gibb166] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [pnl\mtsproc] ******/
CREATE USER [pnl\mtsproc] FOR LOGIN [PNL\MTSProc] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [RBAC-DMS_Developer] ******/
CREATE USER [RBAC-DMS_Developer] FOR LOGIN [PNL\EMSL-Prism.Users.Developers]
GO
/****** Object:  User [RBAC-DMS_Guest] ******/
CREATE USER [RBAC-DMS_Guest] FOR LOGIN [PNL\EMSL-Prism.Users.DMS_Guest]
GO
/****** Object:  User [RBAC-DMS_User] ******/
CREATE USER [RBAC-DMS_User] FOR LOGIN [PNL\EMSL-Prism.Users.DMS_User]
GO
/****** Object:  User [RBAC-Web_Analysis] ******/
CREATE USER [RBAC-Web_Analysis] FOR LOGIN [PNL\EMSL-Prism.Users.Web_Analysis]
GO
/****** Object:  User [svc-dms] ******/
CREATE USER [svc-dms] FOR LOGIN [PNL\svc-dms] WITH DEFAULT_SCHEMA=[dbo]
GO
GRANT SHOWPLAN TO [DDL_Viewer] AS [dbo]
GO
GRANT CONNECT TO [DMSReader] AS [dbo]
GO
GRANT SHOWPLAN TO [DMSReader] AS [dbo]
GO
GRANT CONNECT TO [DMSWebUser] AS [dbo]
GO
GRANT SHOWPLAN TO [DMSWebUser] AS [dbo]
GO
GRANT CONNECT TO [GIGASAX\ftms] AS [dbo]
GO
GRANT CONNECT TO [GIGASAX\msdadmin] AS [dbo]
GO
GRANT CONNECT TO [LOC-DMS_Ops_Admin] AS [dbo]
GO
GRANT CONNECT TO [NT AUTHORITY\SYSTEM] AS [dbo]
GO
GRANT CONNECT TO [PNL\D3L243] AS [dbo]
GO
GRANT CONNECT TO [PNL\D3M578] AS [dbo]
GO
GRANT CONNECT TO [pnl\gibb166] AS [dbo]
GO
GRANT CONNECT TO [pnl\mtsproc] AS [dbo]
GO
GRANT CONNECT TO [RBAC-DMS_Developer] AS [dbo]
GO
GRANT CONNECT TO [RBAC-DMS_Guest] AS [dbo]
GO
GRANT CONNECT TO [RBAC-DMS_User] AS [dbo]
GO
GRANT CONNECT TO [RBAC-Web_Analysis] AS [dbo]
GO
GRANT CONNECT TO [svc-dms] AS [dbo]
GO
ALTER DATABASE [DMS_Pipeline] SET  READ_WRITE 
GO
