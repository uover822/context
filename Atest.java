import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;

import com.metatags.client.MetaClient;

import com.metatags.common.Descriptor;
import com.metatags.common.Property;
import com.metatags.common.Associate;
import com.metatags.common.Relation;

public class Atest {

	public MetaClient client;

	public Atest(MetaClient _client) {
		this.client = _client;
	}

	public boolean qualify(LinkedHashSet _set, String _rtype, String _ptype) {

		Associate associate;
		String type;
		Descriptor descriptor;
		Property property;
		Iterator list = _set.iterator();
		String _gid = "graph";

		boolean state = false;

		if (list != null) {
			Iterator i;
			Relation relation;
			while (list.hasNext()) {
				associate = client.getAssociate(_gid, (String)list.next());
				i = associate.getRelations().iterator();
				while (i.hasNext()) {
					relation = client.getRelation(_gid, (String)i.next());
					if (relation.getType().equals(_rtype)) {
						descriptor = client.getDescriptor(_gid, associate.getTarget());
						property = descriptor.getProperty(_ptype);
						if (property != null)
							state = true;
						break;
					}
				}
			}
		}

		return state;
	}

	public String qualify(LinkedHashMap _properties, String _ptype) {

		Property property;

		if (_properties != null) {
			property = (Property)_properties.get(_ptype);
			if (property != null)
				return (String)property.getValue();
		}

		return null;
	}
}
