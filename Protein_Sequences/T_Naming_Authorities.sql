/****** Object:  Table [dbo].[T_Naming_Authorities] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Naming_Authorities](
	[Authority_ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Web_Address] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Naming_Authorities] PRIMARY KEY CLUSTERED 
(
	[Authority_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
