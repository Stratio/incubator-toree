package org.apache.toree.magic.builtin

import java.io.PrintStream

import org.apache.toree.magic.LineMagic
import org.apache.toree.magic.dependencies.IncludeOutputStream

class Stratio extends LineMagic with IncludeOutputStream {
  private lazy val printStream = new PrintStream(outputStream)

  override def execute(code: String): Unit = {
    printStream.println(
      s"Stratio es una start-up con sedes en Madrid y Silicon Valley, y con producto propio: una plataforma " +
      s"avanzada de Big Data basada en Spark y que permite utilizar cualquier base de datos noSQL.\n" +
      s"Una gran sencillez de instalación y uso, velocidad, y sin dependencia de proveedores (no vendors lock-in) son " +
      s"su propuesta de valor, condensada en el claim “Big Data, a child’s play”. Ante un mundo complejo representado " +
      s"con imágenes de ciudades caóticas (atascos de tráfico, gente anónima mirando sus pantallas, Internet de las " +
      s"Cosas…), Stratio aporta un enfoque humano, cercano y en plano corto.")
  }
}
