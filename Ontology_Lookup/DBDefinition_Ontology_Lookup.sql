/****** Object:  Database [Ontology_Lookup] ******/
CREATE DATABASE [Ontology_Lookup] ON  PRIMARY 
( NAME = N'Ontology_Lookup', FILENAME = N'I:\SqlServerData\Ontology_Lookup.mdf' , SIZE = 1458112KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'Ontology_Lookup_log', FILENAME = N'H:\SqlServerData\Ontology_Lookup_log.ldf' , SIZE = 911360KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
 COLLATE SQL_Latin1_General_CP1_CI_AS
GO
ALTER DATABASE [Ontology_Lookup] SET COMPATIBILITY_LEVEL = 100
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
ALTER DATABASE [Ontology_Lookup] SET  READ_WRITE 
GO
ALTER DATABASE [Ontology_Lookup] SET RECOVERY BULK_LOGGED 
GO
ALTER DATABASE [Ontology_Lookup] SET  MULTI_USER 
GO
ALTER DATABASE [Ontology_Lookup] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [Ontology_Lookup] SET DB_CHAINING OFF 
GO
