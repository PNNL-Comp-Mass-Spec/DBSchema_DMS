/****** Object:  Table [dbo].[T_Acceptable_Param_Entry_Types] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Acceptable_Param_Entry_Types](
	[Param_Entry_Type_ID] [int] IDENTITY(1,1) NOT NULL,
	[Param_Entry_Type_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Formatting_String] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]

GO
