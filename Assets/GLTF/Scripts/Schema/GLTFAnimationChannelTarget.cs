using System;
using GLTF.JsonExtensions;
using Newtonsoft.Json;

namespace GLTF
{
    /// <summary>
    /// The index of the node and TRS property that an animation channel targets.
    /// </summary>
    public class GLTFAnimationChannelTarget : GLTFProperty
    {
        /// <summary>
        /// The index of the node to target.
        /// </summary>
        public GLTFNodeId Node;

        /// <summary>
        /// The name of the node's TRS property to modify.
        /// </summary>
        public GLTFAnimationChannelPath Path;

        public static GLTFAnimationChannelTarget Deserialize(GLTFRoot root, JsonReader reader)
        {
            var animationChannelTarget = new GLTFAnimationChannelTarget();

            if (reader.Read() && reader.TokenType != JsonToken.StartObject)
            {
                throw new Exception("Animation channel target must be an object.");
            }

            while (reader.Read() && reader.TokenType == JsonToken.PropertyName)
            {
                var curProp = reader.Value.ToString();

                switch (curProp)
                {
                    case "node":
                        animationChannelTarget.Node = GLTFNodeId.Deserialize(root, reader);
                        break;
                    case "path":
                        animationChannelTarget.Path = reader.ReadStringEnum<GLTFAnimationChannelPath>();
                        break;
	                default:
		                animationChannelTarget.DefaultPropertyDeserializer(root, reader);
		                break;
				}
            }

            return animationChannelTarget;
        }

        public override void Serialize(JsonWriter writer)
        {
            writer.WriteStartObject();

            writer.WritePropertyName("node");
            writer.WriteValue(Node.Id);

            writer.WritePropertyName("path");
            writer.WriteValue(Path.ToString());

            base.Serialize(writer);

            writer.WriteEndObject();
        }
    }

    public enum GLTFAnimationChannelPath
    {
        translation,
        rotation,
        scale
    }
}
