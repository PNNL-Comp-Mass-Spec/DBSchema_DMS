/****** Object:  Table [dbo].[T_Creation_Option_Keywords] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Creation_Option_Keywords](
	[Keyword_ID] [int] IDENTITY(1,1) NOT NULL,
	[Keyword] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Display] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Default_Value] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IsRequired] [tinyint] NOT NULL,
 CONSTRAINT [PK_T_Creation_Option_Keywords] PRIMARY KEY CLUSTERED 
(
	[Keyword_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Creation_Option_Keywords] ADD  CONSTRAINT [DF_T_Creation_Option_Keywords_IsRequired]  DEFAULT (0) FOR [IsRequired]
GO
