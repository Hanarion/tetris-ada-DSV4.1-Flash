with SDL.Video.Renderers;
with SDL.Video.Palettes;

package Tetris_Font is
   Glyph_Width  : constant := 5;
   Glyph_Height : constant := 7;

   procedure Draw_Text
     (Rend   : in out SDL.Video.Renderers.Renderer;
      X, Y   : Integer;
      Scale  : Positive;
      Text   : String;
      Colour : SDL.Video.Palettes.Colour);

   function Text_Width (Text : String; Scale : Positive) return Natural;
end Tetris_Font;
