/****** Object:  Table [dbo].[T_Experiment_Plex_Channel_Type_Name] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Experiment_Plex_Channel_Type_Name](
	[Channel_Type_ID] [tinyint] NOT NULL,
	[Channel_Type_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Experiment_Plex_Channel_Types] PRIMARY KEY CLUSTERED 
(
	[Channel_Type_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
