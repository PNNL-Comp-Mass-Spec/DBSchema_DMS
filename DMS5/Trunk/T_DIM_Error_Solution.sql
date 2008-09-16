/****** Object:  Table [dbo].[T_DIM_Error_Solution] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_DIM_Error_Solution](
	[Error_Text] [varchar](150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Solution] [varchar](1000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_Error_Text] PRIMARY KEY NONCLUSTERED 
(
	[Error_Text] ASC
)WITH (IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
