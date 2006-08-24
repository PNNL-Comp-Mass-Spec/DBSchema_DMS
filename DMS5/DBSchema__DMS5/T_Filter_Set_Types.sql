/****** Object:  Table [dbo].[T_Filter_Set_Types] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Filter_Set_Types](
	[Filter_Type_ID] [int] IDENTITY(1,1) NOT NULL,
	[Filter_Type_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Filter_Set_Types] PRIMARY KEY CLUSTERED 
(
	[Filter_Type_ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
