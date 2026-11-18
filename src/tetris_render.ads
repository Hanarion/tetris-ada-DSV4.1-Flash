with Tetris_Game;
with SDL.Video.Renderers;

package Tetris_Render is
   Window_Width  : constant := 660;
   Window_Height : constant := 720;

   procedure Draw
     (Rend   : in out SDL.Video.Renderers.Renderer;
      G      : Tetris_Game.Game;
      Paused : Boolean);
end Tetris_Render;
