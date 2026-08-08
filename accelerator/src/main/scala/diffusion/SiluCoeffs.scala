package FLOOD_Accelerator.diffusion

object SiluCoeffs {
  final case class SiluSegment(startQ8: Int, endQ8: Int, slopeQ16: Int, interceptQ8: Int)

  val segments16: Seq[SiluSegment] = Seq(
    SiluSegment(-2048, -1792, 0, -71),
    SiluSegment(-1792, -1536, 0, -71),
    SiluSegment(-1536, -1280, 0, -71),
    SiluSegment(-1280, -1024, 0, -71),
    SiluSegment(-1024, -768, 0, -71),
    SiluSegment(-768, -512, 0, -71),
    SiluSegment(-512, -256, 624, -66),
    SiluSegment(-256, 0, 17625, 1),
    SiluSegment(0, 256, 47911, 1),
    SiluSegment(256, 512, 67537, -77),
    SiluSegment(512, 768, 71836, -110),
    SiluSegment(768, 1024, 70145, -90),
    SiluSegment(1024, 1280, 68058, -57),
    SiluSegment(1280, 1536, 66757, -33),
    SiluSegment(1536, 1792, 66090, -17),
    SiluSegment(1792, 2048, 65778, -9)
  )

  val segments32: Seq[SiluSegment] = Seq(
    SiluSegment(-2048, -1920, 0, -71),
    SiluSegment(-1920, -1792, 0, -71),
    SiluSegment(-1792, -1664, 0, -71),
    SiluSegment(-1664, -1536, 0, -71),
    SiluSegment(-1536, -1408, 0, -71),
    SiluSegment(-1408, -1280, 0, -71),
    SiluSegment(-1280, -1152, 0, -71),
    SiluSegment(-1152, -1024, 0, -71),
    SiluSegment(-1024, -896, 0, -71),
    SiluSegment(-896, -768, 0, -71),
    SiluSegment(-768, -640, 0, -71),
    SiluSegment(-640, -512, 0, -71),
    SiluSegment(-512, -384, 0, -71),
    SiluSegment(-384, -256, 1248, -64),
    SiluSegment(-256, -128, 10508, -28),
    SiluSegment(-128, 0, 24743, 0),
    SiluSegment(0, 128, 40793, 0),
    SiluSegment(128, 256, 55028, -27),
    SiluSegment(256, 384, 64920, -67),
    SiluSegment(384, 512, 70154, -97),
    SiluSegment(512, 640, 71927, -111),
    SiluSegment(640, 768, 71745, -110),
    SiluSegment(768, 896, 70738, -97),
    SiluSegment(896, 1024, 69553, -81),
    SiluSegment(1024, 1152, 68486, -64),
    SiluSegment(1152, 1280, 67630, -50),
    SiluSegment(1280, 1408, 66988, -37),
    SiluSegment(1408, 1536, 66526, -27),
    SiluSegment(1536, 1664, 66202, -20),
    SiluSegment(1664, 1792, 65979, -13),
    SiluSegment(1792, 1920, 65828, -10),
    SiluSegment(1920, 2048, 65728, -7)
  )
}
