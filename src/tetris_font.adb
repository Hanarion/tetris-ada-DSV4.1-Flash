with Interfaces; use Interfaces;
with SDL;
with SDL.Video.Rectangles;

package body Tetris_Font is

   --  Each row is a 5-bit mask, MSB = leftmost pixel.
   type Glyph is array (0 .. 6) of Unsigned_8;

   type Glyphs is
     (Space, Bang, Dash, Dot, Colon, Slash, Less, Greater, Plus,
      Zero, One, Two, Three, Four, Five, Six, Seven, Eight, Nine,
      A, B, C, D, E, F, G, H, I, J, K, L, M,
      N, O, P, Q, R, S, T, U, V, W, X, Y, Z);

   Font : constant array (Glyphs) of Glyph :=
     (Space   => (0, 0, 0, 0, 0, 0, 0),
      Bang    => (2#00100#, 2#00100#, 2#00100#, 2#00100#, 2#00100#, 2#00000#, 2#00100#),
      Dash    => (2#00000#, 2#00000#, 2#00000#, 2#11111#, 2#00000#, 2#00000#, 2#00000#),
      Dot     => (2#00000#, 2#00000#, 2#00000#, 2#00000#, 2#00000#, 2#01100#, 2#01100#),
      Colon   => (2#00000#, 2#01100#, 2#01100#, 2#00000#, 2#01100#, 2#01100#, 2#00000#),
      Slash   => (2#00001#, 2#00010#, 2#00010#, 2#00100#, 2#01000#, 2#01000#, 2#10000#),
      Less    => (2#00010#, 2#00100#, 2#01000#, 2#10000#, 2#01000#, 2#00100#, 2#00010#),
      Greater => (2#01000#, 2#00100#, 2#00010#, 2#00001#, 2#00010#, 2#00100#, 2#01000#),
      Plus    => (2#00000#, 2#00100#, 2#00100#, 2#11111#, 2#00100#, 2#00100#, 2#00000#),

      Zero  => (2#01110#, 2#10001#, 2#10011#, 2#10101#, 2#11001#, 2#10001#, 2#01110#),
      One   => (2#00100#, 2#01100#, 2#00100#, 2#00100#, 2#00100#, 2#00100#, 2#01110#),
      Two   => (2#01110#, 2#10001#, 2#00001#, 2#00010#, 2#00100#, 2#01000#, 2#11111#),
      Three => (2#11111#, 2#00010#, 2#00100#, 2#00010#, 2#00001#, 2#10001#, 2#01110#),
      Four  => (2#00010#, 2#00110#, 2#01010#, 2#10010#, 2#11111#, 2#00010#, 2#00010#),
      Five  => (2#11111#, 2#10000#, 2#11110#, 2#00001#, 2#00001#, 2#10001#, 2#01110#),
      Six   => (2#00110#, 2#01000#, 2#10000#, 2#11110#, 2#10001#, 2#10001#, 2#01110#),
      Seven => (2#11111#, 2#00001#, 2#00010#, 2#00100#, 2#01000#, 2#01000#, 2#01000#),
      Eight => (2#01110#, 2#10001#, 2#10001#, 2#01110#, 2#10001#, 2#10001#, 2#01110#),
      Nine  => (2#01110#, 2#10001#, 2#10001#, 2#01111#, 2#00001#, 2#00010#, 2#01100#),

      A => (2#01110#, 2#10001#, 2#10001#, 2#11111#, 2#10001#, 2#10001#, 2#10001#),
      B => (2#11110#, 2#10001#, 2#10001#, 2#11110#, 2#10001#, 2#10001#, 2#11110#),
      C => (2#01110#, 2#10001#, 2#10000#, 2#10000#, 2#10000#, 2#10001#, 2#01110#),
      D => (2#11110#, 2#10001#, 2#10001#, 2#10001#, 2#10001#, 2#10001#, 2#11110#),
      E => (2#11111#, 2#10000#, 2#10000#, 2#11110#, 2#10000#, 2#10000#, 2#11111#),
      F => (2#11111#, 2#10000#, 2#10000#, 2#11110#, 2#10000#, 2#10000#, 2#10000#),
      G => (2#01110#, 2#10001#, 2#10000#, 2#10111#, 2#10001#, 2#10001#, 2#01111#),
      H => (2#10001#, 2#10001#, 2#10001#, 2#11111#, 2#10001#, 2#10001#, 2#10001#),
      I => (2#01110#, 2#00100#, 2#00100#, 2#00100#, 2#00100#, 2#00100#, 2#01110#),
      J => (2#00111#, 2#00010#, 2#00010#, 2#00010#, 2#00010#, 2#10010#, 2#01100#),
      K => (2#10001#, 2#10010#, 2#10100#, 2#11000#, 2#10100#, 2#10010#, 2#10001#),
      L => (2#10000#, 2#10000#, 2#10000#, 2#10000#, 2#10000#, 2#10000#, 2#11111#),
      M => (2#10001#, 2#11011#, 2#10101#, 2#10101#, 2#10001#, 2#10001#, 2#10001#),
      N => (2#10001#, 2#10001#, 2#11001#, 2#10101#, 2#10011#, 2#10001#, 2#10001#),
      O => (2#01110#, 2#10001#, 2#10001#, 2#10001#, 2#10001#, 2#10001#, 2#01110#),
      P => (2#11110#, 2#10001#, 2#10001#, 2#11110#, 2#10000#, 2#10000#, 2#10000#),
      Q => (2#01110#, 2#10001#, 2#10001#, 2#10001#, 2#10101#, 2#10010#, 2#01101#),
      R => (2#11110#, 2#10001#, 2#10001#, 2#11110#, 2#10100#, 2#10010#, 2#10001#),
      S => (2#01111#, 2#10000#, 2#10000#, 2#01110#, 2#00001#, 2#00001#, 2#11110#),
      T => (2#11111#, 2#00100#, 2#00100#, 2#00100#, 2#00100#, 2#00100#, 2#00100#),
      U => (2#10001#, 2#10001#, 2#10001#, 2#10001#, 2#10001#, 2#10001#, 2#01110#),
      V => (2#10001#, 2#10001#, 2#10001#, 2#10001#, 2#10001#, 2#01010#, 2#00100#),
      W => (2#10001#, 2#10001#, 2#10001#, 2#10101#, 2#10101#, 2#10101#, 2#01010#),
      X => (2#10001#, 2#10001#, 2#01010#, 2#00100#, 2#01010#, 2#10001#, 2#10001#),
      Y => (2#10001#, 2#10001#, 2#01010#, 2#00100#, 2#00100#, 2#00100#, 2#00100#),
      Z => (2#11111#, 2#00001#, 2#00010#, 2#00100#, 2#01000#, 2#10000#, 2#11111#));

   function Glyph_Of (Ch : Character) return Glyphs is
   begin
      case Ch is
         when ' '  => return Space;
         when '!'  => return Bang;
         when '-'  => return Dash;
         when '.'  => return Dot;
         when ':'  => return Colon;
         when '/'  => return Slash;
         when '<'  => return Less;
         when '>'  => return Greater;
         when '+'  => return Plus;
         when '0'  => return Zero;
         when '1'  => return One;
         when '2'  => return Two;
         when '3'  => return Three;
         when '4'  => return Four;
         when '5'  => return Five;
         when '6'  => return Six;
         when '7'  => return Seven;
         when '8'  => return Eight;
         when '9'  => return Nine;
         when 'A' | 'a' => return A;
         when 'B' | 'b' => return B;
         when 'C' | 'c' => return C;
         when 'D' | 'd' => return D;
         when 'E' | 'e' => return E;
         when 'F' | 'f' => return F;
         when 'G' | 'g' => return G;
         when 'H' | 'h' => return H;
         when 'I' | 'i' => return I;
         when 'J' | 'j' => return J;
         when 'K' | 'k' => return K;
         when 'L' | 'l' => return L;
         when 'M' | 'm' => return M;
         when 'N' | 'n' => return N;
         when 'O' | 'o' => return O;
         when 'P' | 'p' => return P;
         when 'Q' | 'q' => return Q;
         when 'R' | 'r' => return R;
         when 'S' | 's' => return S;
         when 'T' | 't' => return T;
         when 'U' | 'u' => return U;
         when 'V' | 'v' => return V;
         when 'W' | 'w' => return W;
         when 'X' | 'x' => return X;
         when 'Y' | 'y' => return Y;
         when 'Z' | 'z' => return Z;
         when others => return Space;
      end case;
   end Glyph_Of;

   function Text_Width (Text : String; Scale : Positive) return Natural is
   begin
      if Text'Length = 0 then
         return 0;
      end if;
      return Text'Length * (Glyph_Width + 1) * Scale - Scale;
   end Text_Width;

   procedure Draw_Text
     (Rend   : in out SDL.Video.Renderers.Renderer;
      X, Y   : Integer;
      Scale  : Positive;
      Text   : String;
      Colour : SDL.Video.Palettes.Colour)
   is
      Pen_X : Integer := X;
   begin
      Rend.Set_Draw_Colour (Colour);

      for Ch of Text loop
         declare
            G : constant Glyph := Font (Glyph_Of (Ch));
         begin
            for Row in 0 .. 6 loop
               for Col in 0 .. 4 loop
                  if (G (Row) and Shift_Left (Unsigned_8 (1), 4 - Col)) /= 0 then
                     Rend.Fill
                       (SDL.Video.Rectangles.Rectangle'
                          (X      => SDL.Coordinate (Pen_X + Col * Scale),
                           Y      => SDL.Coordinate (Y + Row * Scale),
                           Width  => SDL.Natural_Dimension (Scale),
                           Height => SDL.Natural_Dimension (Scale)));
                  end if;
               end loop;
            end loop;
         end;
         Pen_X := Pen_X + (Glyph_Width + 1) * Scale;
      end loop;
   end Draw_Text;

end Tetris_Font;
