/****** Object:  Table [dbo].[T_Dataset_QC_Curation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Dataset_QC_Curation](
	[Dataset_ID] [int] NOT NULL,
	[Dataset] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Dataset_Type] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Instrument_Category] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Used_for_Training] [varchar](4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Used_for_Testing] [varchar](4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Used_for_Validation] [varchar](4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Curated_Quality] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Curated_Comment] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PRIDE_Accession] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Dataset_QC_Curation] PRIMARY KEY CLUSTERED 
(
	[Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
