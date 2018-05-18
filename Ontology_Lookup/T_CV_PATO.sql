/****** Object:  Table [dbo].[T_CV_PATO] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_CV_PATO](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Term_PK] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Term_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Identifier] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Is_Leaf] [tinyint] NOT NULL,
	[Parent_term_name] [varchar](400) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Parent_term_ID] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[GrandParent_term_name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[GrandParent_term_ID] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entered] [smalldatetime] NOT NULL,
	[Updated] [smalldatetime] NOT NULL,
 CONSTRAINT [PK_T_CV_PATO] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_CV_PATO] ADD  CONSTRAINT [DF_T_CV_PATO_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_CV_PATO] ADD  CONSTRAINT [DF_T_CV_PATO_Updated]  DEFAULT (getdate()) FOR [Updated]
GO
