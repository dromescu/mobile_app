"""Generate binary proto file from text format."""

def convert_java_content(proto_message):
    content = """
    package package_name;

    import com.google.protobuf.TextFormat;
    import java.io.*;

    public final class Convert {
      public static void main(String args[]) throws FileNotFoundException, IOException {
        BufferedReader br = new BufferedReader(new FileReader(args[0]));
        class_name.Builder builder = class_name.newBuilder();
        TextFormat.merge(br, builder);
        builder.build().writeTo(System.out);
      }
    }
    """
    package_name = proto_message[:proto_message.rfind(".")]
    class_name = proto_message[proto_message.rfind(".") + 1:]

    return content.replace("package_name", package_name).replace("class_name", class_name)

def text_to_bin(name, src, out, proto_message, proto_deps):
    """Convert a text proto file to binary file.

    Modifying the text proto file is error-prone. Using this utility to
    convert text file to binary file help the debugging process since
    error will be spotted at compile time not runtime. Furthurmore,
    parsing a binary proto file is much more efficient than a text one.

    Args:
        name: name of the rule.
        src: the text file to convert.
        out: target output filename.
        proto_message: name of the proto message including package name.
        proto_deps: the java proto library that proto_message belongs to.
    """

    native.genrule(
        name = "gen_convert_java",
        outs = ["Convert.java"],
        cmd = "echo '" + convert_java_content(proto_message) + "' > $@",
    )

    native.java_binary(
        name = "Convert",
        srcs = [
            "Convert.java",
        ],
        main_class = "org.mlperf.proto.Convert",
        deps = proto_deps + [
            "@com_google_protobuf//:protobuf_java",
        ],
    )

    native.genrule(
        name = name,
        srcs = [src],
        outs = [out],
        cmd = ("$(locations :Convert)" +
               " $(location " + src + ") > $@"),
        exec_tools = [":Convert"],
    )
