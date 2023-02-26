/****** Object:  Database [Ontology_Lookup] ******/
CREATE DATABASE [Ontology_Lookup]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Ontology_Lookup', FILENAME = N'J:\SQLServerData\Ontology_Lookup.mdf' , SIZE = 5049344KB , MAXSIZE = UNLIMITED, FILEGROWTH = 262144KB )
 LOG ON 
( NAME = N'Ontology_Lookup_log', FILENAME = N'H:\SQLServerData\Ontology_Lookup_log.ldf' , SIZE = 273216KB , MAXSIZE = 2048GB , FILEGROWTH = 131072KB )
 COLLATE SQL_Latin1_General_CP1_CI_AS
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [Ontology_Lookup].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [Ontology_Lookup] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [Ontology_Lookup] SET ANSI_NULLS ON 
GO
ALTER DATABASE [Ontology_Lookup] SET ANSI_PADDING ON 
GO
ALTER DATABASE [Ontology_Lookup] SET ANSI_WARNINGS ON 
GO
ALTER DATABASE [Ontology_Lookup] SET ARITHABORT ON 
GO
ALTER DATABASE [Ontology_Lookup] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [Ontology_Lookup] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [Ontology_Lookup] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [Ontology_Lookup] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [Ontology_Lookup] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [Ontology_Lookup] SET CONCAT_NULL_YIELDS_NULL ON 
GO
ALTER DATABASE [Ontology_Lookup] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [Ontology_Lookup] SET QUOTED_IDENTIFIER ON 
GO
ALTER DATABASE [Ontology_Lookup] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [Ontology_Lookup] SET  DISABLE_BROKER 
GO
ALTER DATABASE [Ontology_Lookup] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [Ontology_Lookup] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [Ontology_Lookup] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [Ontology_Lookup] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [Ontology_Lookup] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [Ontology_Lookup] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [Ontology_Lookup] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [Ontology_Lookup] SET RECOVERY FULL 
GO
ALTER DATABASE [Ontology_Lookup] SET  MULTI_USER 
GO
ALTER DATABASE [Ontology_Lookup] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [Ontology_Lookup] SET DB_CHAINING OFF 
GO
ALTER DATABASE [Ontology_Lookup] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [Ontology_Lookup] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
ALTER DATABASE [Ontology_Lookup] SET DELAYED_DURABILITY = DISABLED 
GO
USE [Ontology_Lookup]
GO
/****** Object:  User [DMSReader] ******/
CREATE USER [DMSReader] FOR LOGIN [DMSReader] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [DMSWebUser] ******/
CREATE USER [DMSWebUser] FOR LOGIN [DMSWebUser] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [PNL\D3M578] ******/
CREATE USER [PNL\D3M578] FOR LOGIN [PNL\D3M578] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [PNL\D3M580] ******/
CREATE USER [PNL\D3M580] FOR LOGIN [PNL\D3M580] WITH DEFAULT_SCHEMA=[PNL\D3M580]
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
GRANT CONNECT TO [PNL\D3M578] AS [dbo]
GO
GRANT CONNECT TO [RBAC-DMS_Developer] AS [dbo]
GO
GRANT CONNECT TO [RBAC-DMS_Guest] AS [dbo]
GO
GRANT CONNECT TO [RBAC-DMS_User] AS [dbo]
GO
GRANT CONNECT TO [svc-dms] AS [dbo]
GO
ALTER DATABASE [Ontology_Lookup] SET  READ_WRITE 
GO
