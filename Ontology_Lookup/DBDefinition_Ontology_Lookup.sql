/****** Object:  Database [Ontology_Lookup] ******/
CREATE DATABASE [Ontology_Lookup]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Ontology_Lookup', FILENAME = N'I:\SqlServerData\Ontology_Lookup.mdf' , SIZE = 4086208KB , MAXSIZE = UNLIMITED, FILEGROWTH = 262144KB )
 LOG ON 
( NAME = N'Ontology_Lookup_log', FILENAME = N'H:\SQLServerData\Ontology_Lookup_log.ldf' , SIZE = 3064128KB , MAXSIZE = 2048GB , FILEGROWTH = 131072KB )
 COLLATE SQL_Latin1_General_CP1_CI_AS
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [Ontology_Lookup].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [Ontology_Lookup] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [Ontology_Lookup] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [Ontology_Lookup] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [Ontology_Lookup] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [Ontology_Lookup] SET ARITHABORT OFF 
GO
ALTER DATABASE [Ontology_Lookup] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [Ontology_Lookup] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [Ontology_Lookup] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [Ontology_Lookup] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [Ontology_Lookup] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [Ontology_Lookup] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [Ontology_Lookup] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [Ontology_Lookup] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [Ontology_Lookup] SET QUOTED_IDENTIFIER OFF 
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
USE [Ontology_Lookup]
GO
/****** Object:  User [d3m578] ******/
CREATE USER [d3m578] FOR LOGIN [PNL\D3M578] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [DMSReader] ******/
CREATE USER [DMSReader] FOR LOGIN [DMSReader] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [DMSWebUser] ******/
CREATE USER [DMSWebUser] FOR LOGIN [DMSWebUser] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [svc-dms] ******/
CREATE USER [svc-dms] FOR LOGIN [PNL\svc-dms] WITH DEFAULT_SCHEMA=[dbo]
GO
GRANT CONNECT TO [d3m578] AS [dbo]
GO
GRANT CONNECT TO [DMSReader] AS [dbo]
GO
GRANT SHOWPLAN TO [DMSReader] AS [dbo]
GO
GRANT CONNECT TO [DMSWebUser] AS [dbo]
GO
GRANT SHOWPLAN TO [DMSWebUser] AS [dbo]
GO
GRANT CONNECT TO [svc-dms] AS [dbo]
GO
ALTER DATABASE [Ontology_Lookup] SET  READ_WRITE 
GO
