/****** Object:  Database [Protein_Sequences] ******/
CREATE DATABASE [Protein_Sequences] ON  PRIMARY 
( NAME = N'Protein_Sequences_Data', FILENAME = N'J:\SQLServerData\Protein_Sequences.mdf' , SIZE = 186294784KB , MAXSIZE = UNLIMITED, FILEGROWTH = 768000KB )
 LOG ON 
( NAME = N'Protein_Sequences_Log', FILENAME = N'K:\SQLServerData\Protein_Sequences_Log.LDF' , SIZE = 97832640KB , MAXSIZE = UNLIMITED, FILEGROWTH = 768000KB )
 COLLATE SQL_Latin1_General_CP1_CI_AS
GO
ALTER DATABASE [Protein_Sequences] SET COMPATIBILITY_LEVEL = 100
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [Protein_Sequences].[dbo].[sp_fulltext_database] @action = 'disable'
end
GO
ALTER DATABASE [Protein_Sequences] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [Protein_Sequences] SET ANSI_NULLS ON 
GO
ALTER DATABASE [Protein_Sequences] SET ANSI_PADDING ON 
GO
ALTER DATABASE [Protein_Sequences] SET ANSI_WARNINGS ON 
GO
ALTER DATABASE [Protein_Sequences] SET ARITHABORT ON 
GO
ALTER DATABASE [Protein_Sequences] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [Protein_Sequences] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [Protein_Sequences] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [Protein_Sequences] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [Protein_Sequences] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [Protein_Sequences] SET CONCAT_NULL_YIELDS_NULL ON 
GO
ALTER DATABASE [Protein_Sequences] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [Protein_Sequences] SET QUOTED_IDENTIFIER ON 
GO
ALTER DATABASE [Protein_Sequences] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [Protein_Sequences] SET  DISABLE_BROKER 
GO
ALTER DATABASE [Protein_Sequences] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [Protein_Sequences] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [Protein_Sequences] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [Protein_Sequences] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [Protein_Sequences] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [Protein_Sequences] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [Protein_Sequences] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [Protein_Sequences] SET RECOVERY FULL 
GO
ALTER DATABASE [Protein_Sequences] SET  MULTI_USER 
GO
ALTER DATABASE [Protein_Sequences] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [Protein_Sequences] SET DB_CHAINING OFF 
GO
USE [Protein_Sequences]
GO
/****** Object:  User [DMSReader] ******/
CREATE USER [DMSReader] FOR LOGIN [DMSReader] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [DMSWebUser] ******/
CREATE USER [DMSWebUser] FOR LOGIN [DMSWebUser] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [EMSL-Prism.Users.DMS_Guest] ******/
CREATE USER [EMSL-Prism.Users.DMS_Guest] FOR LOGIN [PNL\EMSL-Prism.Users.DMS_Guest]
GO
/****** Object:  User [EMSL-Prism.Users.DMS_User] ******/
CREATE USER [EMSL-Prism.Users.DMS_User] FOR LOGIN [PNL\EMSL-Prism.Users.DMS_User]
GO
/****** Object:  User [emsl-prism.Users.Web_Analysis] ******/
CREATE USER [emsl-prism.Users.Web_Analysis] FOR LOGIN [PNL\EMSL-Prism.Users.Web_Analysis]
GO
/****** Object:  User [MTAdmin] ******/
CREATE USER [MTAdmin] FOR LOGIN [mtadmin] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [MTS_DB_Dev] ******/
CREATE USER [MTS_DB_Dev] FOR LOGIN [ProteinSeqs\MTS_DB_Dev]
GO
/****** Object:  User [MTS_DB_Lite] ******/
CREATE USER [MTS_DB_Lite] FOR LOGIN [ProteinSeqs\MTS_DB_Lite]
GO
/****** Object:  User [MTS_DB_Reader] ******/
CREATE USER [MTS_DB_Reader] FOR LOGIN [ProteinSeqs\MTS_DB_Reader]
GO
/****** Object:  User [MTUser] ******/
CREATE USER [MTUser] FOR LOGIN [mtuser] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [pnl\d3l243] ******/
CREATE USER [pnl\d3l243] FOR LOGIN [PNL\D3L243] WITH DEFAULT_SCHEMA=[pnl\d3l243]
GO
/****** Object:  User [PRISMSeqReader] ******/
CREATE USER [PRISMSeqReader] FOR LOGIN [PRISMSeqReader] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [proteinseqs\ftms] ******/
CREATE USER [proteinseqs\ftms] FOR LOGIN [PROTEINSEQS\ftms] WITH DEFAULT_SCHEMA=[proteinseqs\ftms]
GO
/****** Object:  User [Proteinseqs\msdadmin] ******/
CREATE USER [Proteinseqs\msdadmin] FOR LOGIN [Proteinseqs\msdadmin] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [svc-dms] ******/
CREATE USER [svc-dms] FOR LOGIN [PNL\svc-dms] WITH DEFAULT_SCHEMA=[dbo]
GO
GRANT CONNECT TO [DMSReader] AS [dbo]
GO
GRANT CONNECT TO [DMSWebUser] AS [dbo]
GO
GRANT CONNECT TO [EMSL-Prism.Users.DMS_Guest] AS [dbo]
GO
GRANT CONNECT TO [EMSL-Prism.Users.DMS_User] AS [dbo]
GO
GRANT CONNECT TO [emsl-prism.Users.Web_Analysis] AS [dbo]
GO
GRANT CONNECT TO [MTAdmin] AS [dbo]
GO
GRANT CONNECT TO [MTS_DB_Dev] AS [dbo]
GO
GRANT CONNECT TO [MTS_DB_Lite] AS [dbo]
GO
GRANT CONNECT TO [MTS_DB_Reader] AS [dbo]
GO
GRANT CONNECT TO [MTUser] AS [dbo]
GO
GRANT CONNECT TO [pnl\d3l243] AS [dbo]
GO
GRANT CONNECT TO [PRISMSeqReader] AS [dbo]
GO
GRANT CONNECT TO [proteinseqs\ftms] AS [dbo]
GO
GRANT CONNECT TO [Proteinseqs\msdadmin] AS [dbo]
GO
GRANT CONNECT TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
GRANT CONNECT TO [svc-dms] AS [dbo]
GO
ALTER DATABASE [Protein_Sequences] SET  READ_WRITE 
GO
