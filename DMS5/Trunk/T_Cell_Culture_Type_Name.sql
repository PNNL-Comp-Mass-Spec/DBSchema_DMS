/****** Object:  Table [dbo].[T_Cell_Culture_Type_Name] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Cell_Culture_Type_Name](
	[ID] [int] IDENTITY(100,1) NOT NULL,
	[Name] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Cell_Culture_Type_Name] PRIMARY KEY NONCLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
