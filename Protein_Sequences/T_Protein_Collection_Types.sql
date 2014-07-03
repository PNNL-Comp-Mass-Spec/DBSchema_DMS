/****** Object:  Table [dbo].[T_Protein_Collection_Types] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Protein_Collection_Types](
	[Collection_Type_ID] [tinyint] IDENTITY(3,1) NOT NULL,
	[Type] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Display] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Description] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Protein_Collection_Types] PRIMARY KEY CLUSTERED 
(
	[Collection_Type_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
