/****** Object:  Table [dbo].[T_Enzymes] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Enzymes](
	[Enzyme_ID] [int] IDENTITY(10,1) NOT NULL,
	[Enzyme_Name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[P1] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[P1_Exception] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[P2] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[P2_Exception] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Cleavage_Method] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Cleavage_Offset] [tinyint] NOT NULL,
	[Sequest_Enzyme_Index] [int] NULL,
	[Protein_Collection_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Enzymes] PRIMARY KEY CLUSTERED 
(
	[Enzyme_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Enzymes] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Enzymes] ADD  CONSTRAINT [DF_T_Enzymes_Cleavage_Method]  DEFAULT ('Standard') FOR [Cleavage_Method]
GO
ALTER TABLE [dbo].[T_Enzymes] ADD  CONSTRAINT [DF_T_Enzymes_Cleavage_Offset]  DEFAULT ((1)) FOR [Cleavage_Offset]
GO
