/*
  Copyright (c) 2018, Sylabs, Inc. All rights reserved.

  This software is licensed under a 3-clause BSD license.  Please
  consult LICENSE file distributed with the sources of this project regarding
  your rights to use or distribute this software.
*/

package provisioners

import (
	"fmt"

	"github.com/singularityware/singularity/src/pkg/image"
)

// ShubProvisioner provisions a sandbox environment from a shub
// URI.
type ShubProvisioner struct {
}

// Provision provisions a sandbox from the Shub source URI into the location
// specified by i.
func (p *ShubProvisioner) Provision(i *image.Sandbox) (err error) {
	return fmt.Errorf("Shub provisioner not implemented yet")
}

// NewShubProvisioner returns a ShubProvisioner object from the Shub source
func NewShubProvisioner(src string) (p *ShubProvisioner, err error) {
	return &ShubProvisioner{}, fmt.Errorf("Shub provisioner not supported yet")
}
