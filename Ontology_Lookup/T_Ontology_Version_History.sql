/****** Object:  Table [dbo].[T_Ontology_Version_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Ontology_Version_History](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Ontology] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Version] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Release_Date] [smalldatetime] NULL,
	[Entered_in_DMS] [smalldatetime] NULL,
	[Download_URL] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comments] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Ontology_Version_History] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Ontology_Version_History] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Ontology_Version_History] ADD  CONSTRAINT [DF_T_Ontology_Version_History_Entered_in_DMS]  DEFAULT (getdate()) FOR [Entered_in_DMS]
GO
