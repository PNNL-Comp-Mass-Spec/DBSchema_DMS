/****** Object:  Table [dbo].[T_Enzymes] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Enzymes](
	[Enzyme_ID] [int] IDENTITY(10,1) NOT NULL,
	[Enzyme_Name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[P1] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[P1_Exception] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[P2] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[P2_Exception] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Cleavage_Method] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Enzymes_Cleavage_Method]  DEFAULT ('Standard'),
 CONSTRAINT [PK_T_Enzymes] PRIMARY KEY CLUSTERED 
(
	[Enzyme_ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
