/****** Object:  Table [dbo].[T_Material_Log] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Material_Log](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Date] [datetime] NOT NULL CONSTRAINT [DF_T_Material_Log_Date]  DEFAULT (getdate()),
	[Type] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Item] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Initial_State] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Final_State] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[User_PRN] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Material_Log] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
