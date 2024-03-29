/****** Object:  Table [dbo].[T_Dataset_Archive_Update_State_Name] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Dataset_Archive_Update_State_Name](
	[AUS_stateID] [int] NOT NULL,
	[AUS_name] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [T_Dataset_Archive_Update_State_Name_PK] PRIMARY KEY CLUSTERED 
(
	[AUS_stateID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Dataset_Archive_Update_State_Name] TO [DDL_Viewer] AS [dbo]
GO
