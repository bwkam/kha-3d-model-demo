import kha.math.FastMatrix4;
import kha.graphics4.PipelineState;
import kha.graphics4.Graphics;
import kha.Image;
import Mesh.Texture;
import kha.math.FastVector2;
import kha.math.FastVector3;
import Mesh.Vertex;
import kha.AssetError;
import kha.Blob;
import kha.Assets;
import gltf.GLTF;
import gltf.schema.TGLTF;
import gltf.schema.TGLTFID;
import gltf.types.MeshPrimitive;
import gltf.types.Node;
import haxe.io.Path;

/**
 * A model loaded from a GLTF artifact.
 */
class Model {
	var _gltfRaw:TGLTF; // JSON file
	var _gltfObject:GLTF; // bin file
	var _directory:String;
	var _loadedTextures:Array<Texture> = [];

	var _meshes:Array<Mesh> = [];

	/**
	 * Constructor
	 * @param gl the Lime WebGL render context
	 * @param gltfFilePath an Assets path to the model JSON file
	 * @param gltfBinFilePath an Assets path to the model .bin file
	 */
	public function new(gltfFilePath:String, gltfBinFilePath:String) {
		loadModel(gltfFilePath, gltfBinFilePath);
	}

	public function draw(g:Graphics, proj:FastMatrix4, model:FastMatrix4, view:FastMatrix4) {
		for (mesh in _meshes) {
			mesh.draw(g, proj, model, view);
		}
	}

	function loadModel(gltfFilePath:String, gltfBinFilePath:String):Void {
		var gltfFile = Assets.blobs.backpack_gltf2.readUtf8String();
		var glftBinFile = Assets.blobs.backpack_bin.bytes;

		_gltfRaw = GLTF.parse(gltfFile);
		_gltfObject = GLTF.load(_gltfRaw, [glftBinFile]);
		_directory = Path.directory(gltfFilePath);

		// Process all data to extract and marshal the data for the meshes
		processScene(_gltfObject);
	}

	/**
	 * Process each scene - initially just do scene 0
	 * FIXME - note gltf does not support the scene attribute. In fact GLTF object is documented as representing a glTF scene. Nonetheless it seems to get all scenes - just doesn't support the default scene attribute.
	 * FIXME - MeshPrimitive does not have a mode field
	 * FIXME - MeshPrimitive does not support morph targets
	 * FIXME - BufferView does not handle byteStride. Seems we don't need it for this though
	 * @param model a GLTF 
	 */
	function processScene(model:GLTF):Void {
		var scene = 0;
		var s = model.scenes[scene];
		for (n in s.nodes) {
			processNode(n);
		}
		// for (n in s.nodes[0].children)
		// {
		// 	processMesh(n.mesh);
		// }
	}

	function processNode(node:Node):Void {
		if (node.mesh != null) {
			processMesh(node.mesh);
		}
		if (node.children.length > 0) {
			for (childNode in node.children) {
				processNode(childNode);
			}
		}
	}

	function processMesh(mesh:gltf.types.Mesh):Void {
		if (mesh.primitives == null)
			trace('no primitives on ${mesh.name}');
		for (p in mesh.primitives) {
			var m = processMeshPrimitive(p, mesh.name);
			if (m != null) {
				_meshes.push(m);
			} else {
				trace('got a null mesh');
			}
		}
	}

	function processMeshPrimitive(primitive:MeshPrimitive, meshName:String):Null<Mesh> {
		var positions = primitive.getFloatAttributeValues('POSITION');
		var normals = primitive.getFloatAttributeValues('NORMAL');
		var texcoords = primitive.getFloatAttributeValues('TEXCOORD_0');
		if (texcoords[0] == 0.0) {
			trace('texcoords(${meshName})=${texcoords}');
		}
		if (positions.length != normals.length || Math.ceil(positions.length / 3) != Math.ceil(texcoords.length / 2)) {
			trace('loading aborted - positions, normals and texcoords arrays are different lengths\n'
				+ '    positions=${positions.length}, normals=${normals.length}, texcoods=${texcoords.length}');
			return null;
		}

		// Get the per-vertex data - position, normals and texture coordinates
		var vertexData = new Array<Vertex>();
		for (i in 0...Math.ceil(positions.length / 3)) {
			var p = new FastVector3();
			p.x = positions[3 * i];
			p.y = positions[3 * i + 1];
			p.z = positions[3 * i + 2];

			var n = new FastVector3();
			n.x = normals[3 * i];
			n.y = normals[3 * i + 1];
			n.z = normals[3 * i + 2];

			var t = new FastVector2();
			t.x = texcoords[2 * i];
			t.y = texcoords[2 * i + 1];

			vertexData.push({position: p, normal: n, texCoords: t});
		}
		// Get the indexes for indexed drawing
		var indexData = new Array<Int>();
		for (i in primitive.getIndexValues()) {
			indexData.push(i);
		}

		// Get the textures
		var diffuseMaps = loadMaterialTextures(primitive.material, "texture_diffuse");
		var specularMaps = loadMaterialTextures(primitive.material, "texture_specular");
		var textures = new Array<Mesh.Texture>();
		textures.push(diffuseMaps);
		textures.push(specularMaps);
		// trace('diffusetx=${diffuseMaps.textureId}, ${diffuseMaps.textureType}, ${diffuseMaps.texturePath}');
		// trace('speculartx=${specularMaps.textureId}, ${specularMaps.textureType}, ${specularMaps.texturePath}');
		return new Mesh(vertexData, indexData, textures);
	}

	/**
	 * Load the material texture into the cache and return a Texture object
	 * @param materialId the material id
	 * @param type 
	 * @return Texture
	 */
	function loadMaterialTextures(materialId:TGLTFID, type:String):Texture {
		var textureID = 0;
		for (i in _gltfRaw.images) {
			var path = Path.join([_directory, i.uri]);
			var alreadyLoaded = false;
			for (t in _loadedTextures) {
				if (t.path == path) {
					alreadyLoaded = true;
				}
			}
			if (!alreadyLoaded) {
				var img:Image;
				Assets.loadImageFromPath(path, true, (image:Image) -> img = image, (error:AssetError) -> trace("FUCKING ERROR: " + error));

				var texture = img;
				_loadedTextures.push({
					id: textureID,
					type: textureID == 0 ? "texture_diffuse" : "texture_specular",
					path: path,
					tex: texture
				});
			}
			textureID++;
		}

		return _loadedTextures[type == "texture_diffuse" ? 0 : 1];
	}
}
