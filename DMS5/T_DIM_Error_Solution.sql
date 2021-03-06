/****** Object:  Table [dbo].[T_DIM_Error_Solution] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_DIM_Error_Solution](
	[Error_Text] [varchar](150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Solution] [varchar](1000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_Error_Text] PRIMARY KEY CLUSTERED 
(
	[Error_Text] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_DIM_Error_Solution] TO [DDL_Viewer] AS [dbo]
GO
