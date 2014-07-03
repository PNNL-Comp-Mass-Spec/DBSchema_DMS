/****** Object:  Table [dbo].[T_Reading_Frame_Types] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Reading_Frame_Types](
	[Reading_Frame_Type_ID] [tinyint] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Description] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Reading_Frame_Types] PRIMARY KEY CLUSTERED 
(
	[Reading_Frame_Type_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
