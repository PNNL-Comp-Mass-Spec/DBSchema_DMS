/****** Object:  Database [DMS5] ******/
CREATE DATABASE [DMS5] ON  PRIMARY 
( NAME = N'DMS4_dat', FILENAME = N'H:\SQLServerData\DMS5.mdf' , SIZE = 21549952KB , MAXSIZE = UNLIMITED, FILEGROWTH = 10%)
 LOG ON 
( NAME = N'DMS4_log', FILENAME = N'G:\SQLServerData\DMS5_log.ldf' , SIZE = 8640KB , MAXSIZE = UNLIMITED, FILEGROWTH = 10%)
 COLLATE SQL_Latin1_General_CP1_CI_AS
GO
ALTER DATABASE [DMS5] SET COMPATIBILITY_LEVEL = 100
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [DMS5].[dbo].[sp_fulltext_database] @action = 'disable'
end
GO
ALTER DATABASE [DMS5] SET ANSI_NULL_DEFAULT ON 
GO
ALTER DATABASE [DMS5] SET ANSI_NULLS ON 
GO
ALTER DATABASE [DMS5] SET ANSI_PADDING ON 
GO
ALTER DATABASE [DMS5] SET ANSI_WARNINGS ON 
GO
ALTER DATABASE [DMS5] SET ARITHABORT ON 
GO
ALTER DATABASE [DMS5] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [DMS5] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [DMS5] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [DMS5] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [DMS5] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [DMS5] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [DMS5] SET CONCAT_NULL_YIELDS_NULL ON 
GO
ALTER DATABASE [DMS5] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [DMS5] SET QUOTED_IDENTIFIER ON 
GO
ALTER DATABASE [DMS5] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [DMS5] SET  DISABLE_BROKER 
GO
ALTER DATABASE [DMS5] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [DMS5] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [DMS5] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [DMS5] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [DMS5] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [DMS5] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [DMS5] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [DMS5] SET RECOVERY FULL 
GO
ALTER DATABASE [DMS5] SET  MULTI_USER 
GO
ALTER DATABASE [DMS5] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [DMS5] SET DB_CHAINING OFF 
GO
USE [DMS5]
GO
/****** Object:  User [BUILTIN\Administrators] ******/
CREATE USER [BUILTIN\Administrators] FOR LOGIN [BUILTIN\Administrators]
GO
/****** Object:  User [D3L243] ******/
CREATE USER [D3L243] FOR LOGIN [PNL\D3L243] WITH DEFAULT_SCHEMA=[D3L243]
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
/****** Object:  User [LCMSNetUser] ******/
CREATE USER [LCMSNetUser] FOR LOGIN [LCMSNetUser] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [NWFS_Samba_User] ******/
CREATE USER [NWFS_Samba_User] FOR LOGIN [nwfs_samba_user] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [PNL\brow950] ******/
CREATE USER [PNL\brow950] FOR LOGIN [PNL\brow950] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [PNL\D3M578] ******/
CREATE USER [PNL\D3M578] FOR LOGIN [PNL\D3M578] WITH DEFAULT_SCHEMA=[PNL\D3M578]
GO
/****** Object:  User [PNL\D3M580] ******/
CREATE USER [PNL\D3M580] FOR LOGIN [PNL\D3M580] WITH DEFAULT_SCHEMA=[PNL\D3M580]
GO
/****** Object:  User [PNL\D3Y513] ******/
CREATE USER [PNL\D3Y513] FOR LOGIN [PNL\D3Y513] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [pnl\mtsadmin] ******/
CREATE USER [pnl\mtsadmin] FOR LOGIN [PNL\MTSADMIN] WITH DEFAULT_SCHEMA=[pnl\mtsadmin]
GO
/****** Object:  User [RBAC-DMS_Guest] ******/
CREATE USER [RBAC-DMS_Guest] FOR LOGIN [PNL\EMSL-Prism.Users.DMS_Guest]
GO
/****** Object:  User [RBAC-DMS_User] ******/
CREATE USER [RBAC-DMS_User] FOR LOGIN [PNL\EMSL-Prism.Users.DMS_User]
GO
/****** Object:  User [RBAC-Param_File_Admin] ******/
CREATE USER [RBAC-Param_File_Admin] FOR LOGIN [PNL\EMSL-Prism.Users.Param_File_Admin]
GO
/****** Object:  User [RBAC-Web_Analysis] ******/
CREATE USER [RBAC-Web_Analysis] FOR LOGIN [PNL\EMSL-Prism.Users.Web_Analysis]
GO
/****** Object:  User [svc-dms] ******/
CREATE USER [svc-dms] FOR LOGIN [PNL\svc-dms] WITH DEFAULT_SCHEMA=[dbo]
GO
GRANT CONNECT TO [BUILTIN\Administrators] AS [dbo]
GO
GRANT ALTER TO [D3L243] AS [dbo]
GO
GRANT CONNECT TO [D3L243] AS [dbo]
GO
GRANT SHOWPLAN TO [D3L243] AS [dbo]
GO
GRANT CONNECT TO [DMSMassCorrectionAdder] AS [dbo]
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
GRANT CONNECT TO [LCMSNetUser] AS [dbo]
GO
GRANT CONNECT TO [LCMSOperator] AS [dbo]
GO
GRANT CONNECT TO [LOC-DMS_Archive_Admin] AS [dbo]
GO
GRANT CONNECT TO [LOC-DMS_Archive_Restore] AS [dbo]
GO
GRANT CONNECT TO [LOC-DMS_DS_Entry] AS [dbo]
GO
GRANT CONNECT TO [LOC-DMS_EUS_Admin] AS [dbo]
GO
GRANT CONNECT TO [LOC-DMS_Experiment_Entry] AS [dbo]
GO
GRANT CONNECT TO [LOC-DMS_Instrument_Admin] AS [dbo]
GO
GRANT CONNECT TO [LOC-DMS_LC_Column_Admin] AS [dbo]
GO
GRANT CONNECT TO [LOC-DMS_LCMSNet_User] AS [dbo]
GO
GRANT CONNECT TO [LOC-DMS_Ops_Admin] AS [dbo]
GO
GRANT CONNECT TO [LOC-DMS_Org_Database_Admin] AS [dbo]
GO
GRANT CONNECT TO [LOC-DMS_ParamFile_Admin] AS [dbo]
GO
GRANT CONNECT TO [LOC-DMS_Sample_Prep_Admin] AS [dbo]
GO
GRANT CONNECT TO [LOC-DMS_Storage_Admin] AS [dbo]
GO
GRANT CONNECT TO [LOC-DMS_Web_Run_Scheduler] AS [dbo]
GO
GRANT CONNECT TO [NWFS_Samba_User] AS [dbo]
GO
GRANT CONNECT TO [PNL\brow950] AS [dbo]
GO
GRANT CONNECT TO [PNL\D3M578] AS [dbo]
GO
GRANT SHOWPLAN TO [PNL\D3M578] AS [dbo]
GO
GRANT CONNECT TO [PNL\D3M580] AS [dbo]
GO
GRANT SHOWPLAN TO [PNL\D3M580] AS [dbo]
GO
GRANT CONNECT TO [PNL\D3P214] AS [dbo]
GO
GRANT CONNECT TO [PNL\D3Y513] AS [dbo]
GO
GRANT CONNECT TO [PNL\davi633] AS [dbo]
GO
GRANT CONNECT TO [pnl\mtsadmin] AS [dbo]
GO
GRANT CONNECT TO [PRISMSeqReader] AS [dbo]
GO
GRANT CONNECT TO [RBAC-Analysis_Job_Runner] AS [dbo]
GO
GRANT CONNECT TO [RBAC-DMS_Guest] AS [dbo]
GO
GRANT CONNECT TO [RBAC-DMS_User] AS [dbo]
GO
GRANT SHOWPLAN TO [RBAC-DMS_User] AS [dbo]
GO
GRANT CONNECT TO [RBAC-Param_File_Admin] AS [dbo]
GO
GRANT CONNECT TO [RBAC-Web_Analysis] AS [dbo]
GO
GRANT CONNECT TO [svc-dms] AS [dbo]
GO
ALTER DATABASE [DMS5] SET  READ_WRITE 
GO
