/****** Object:  Table [dbo].[T_Dataset_Create_Queue_State] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Dataset_Create_Queue_State](
	[Queue_State_ID] [int] NOT NULL,
	[Queue_State_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_Dataset_Create_Queue_State] PRIMARY KEY CLUSTERED 
(
	[Queue_State_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
