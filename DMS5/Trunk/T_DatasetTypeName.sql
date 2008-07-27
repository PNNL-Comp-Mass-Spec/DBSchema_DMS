/****** Object:  Table [dbo].[T_DatasetTypeName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_DatasetTypeName](
	[DST_Type_ID] [int] NOT NULL,
	[DST_name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[DST_Description] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DST_Active] [tinyint] NOT NULL CONSTRAINT [DF_T_DatasetTypeName_DST_Active]  DEFAULT (1),
 CONSTRAINT [PK_T_DatasetTypeName] PRIMARY KEY NONCLUSTERED 
(
	[DST_Type_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
